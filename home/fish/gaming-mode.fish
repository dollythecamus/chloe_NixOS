# gaming-mode — park background services to free RAM for a gaming session.
#
#   gaming-mode on                 stop the service list below (one sudo prompt)
#   gaming-mode on --apps          ...and close Discord + the Hermes desktop window
#   gaming-mode off                restart exactly what this script stopped
#   gaming-mode status             what is running now and what it costs
#   gaming-mode toggle             on if off, off if on
#
# Flags: --dry-run  --user-only  --keep-agent  --apps[=discord,hermes]  --no-apps  -h
#
# `off` restarts only what `on` actually stopped, so anything you had already
# stopped by hand stays stopped. State: ~/.local/state/gaming-mode/
#
# Installed verbatim by home-manager as ~/.config/fish/functions/gaming-mode.fish
# (xdg.configFile in home/terminal.nix) so fish autoloads it by filename and the
# __gm_* helpers below land with it. Nothing is masked or disabled: every unit
# comes back on the next boot regardless of the state file.

# ---- helpers ---------------------------------------------------------------

function __gm_usage
    printf '%s\n' \
        'gaming-mode — park background services to free RAM for a gaming session.' \
        '' \
        '  gaming-mode on                 stop the service list (one sudo prompt)' \
        '  gaming-mode on --apps          ...and close Discord + the Hermes desktop window' \
        '  gaming-mode off                restart exactly what on stopped' \
        '  gaming-mode status             what is running now and what it costs' \
        '  gaming-mode toggle             on if off, off if on' \
        '' \
        'Flags: --dry-run  --user-only  --keep-agent  --apps[=discord,hermes]  --no-apps  -h'
end

function __gm_mem_used
    awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{printf "%d", (t-a)/1024}' /proc/meminfo
end

function __gm_mem_avail
    awk '/^MemAvailable:/{printf "%d", $2/1024}' /proc/meminfo
end

function __gm_mem_total
    awk '/^MemTotal:/{printf "%d", $2/1024}' /proc/meminfo
end

function __gm_swap_used
    awk '/^SwapTotal:/{t=$2} /^SwapFree:/{f=$2} END{printf "%d", (t-f)/1024}' /proc/meminfo
end

# __gm_unit_mem <user|system> <unit> — MiB, or "-" when unknown/stopped
function __gm_unit_mem --argument-names scope unit
    set -l v
    if test "$scope" = user
        set v (systemctl --user show -p MemoryCurrent --value $unit 2>/dev/null)
    else
        set v (systemctl show -p MemoryCurrent --value $unit 2>/dev/null)
    end
    if string match -qr '^[0-9]+$' -- "$v"
        math -s0 "$v/1048576"
    else
        printf '-'
    end
end

function __gm_unit_active --argument-names scope unit
    if test "$scope" = user
        systemctl --user is-active --quiet $unit 2>/dev/null
    else
        systemctl is-active --quiet $unit 2>/dev/null
    end
end

# This shell and its ancestors must never be a kill target, even when their
# command line happens to contain the app pattern (e.g. a wrapper that mentions
# the string): without this, an app kill can SIGTERM the shell that ran it.
function __gm_protected
    set -l p $fish_pid
    echo $p
    while true
        set p (awk '/^PPid:/{print $2}' /proc/$p/status 2>/dev/null)
        test -n "$p"; or break
        test "$p" -le 1; and break
        echo $p
    end
end

function __gm_shellish --argument-names a0
    set -l b (string replace -r '.*/' '' -- "$a0")
    contains -- $b bash sh dash zsh fish rbash env sudo doas setsid timeout nice nohup tmux gaming-mode
end

# Patterns are regexes and must match every process of an app (main, renderers,
# zygotes, GPU/network helpers), otherwise both the kill and the RAM figure miss
# most of the tree: Discord's renderers run as .Discord-wrapped, not bin/Discord.
function __gm_app_pattern --argument-names app
    switch $app
        case discord
            printf '%s' "bin/Discord|Discord-wrapped|user-data-dir=$HOME/.config/discord"
        case hermes
            printf '%s' "share/hermes-desktop|user-data-dir=$HOME/.config/Hermes"
        case '*'
            return 1
    end
end

function __gm_app_label --argument-names app
    switch $app
        case discord
            printf 'Discord'
        case hermes
            printf 'Hermes desktop'
    end
end

function __gm_app_launch --argument-names app
    switch $app
        case discord
            printf 'Discord'
        case hermes
            printf 'hermes-desktop'
    end
end

# __gm_app_pids <pattern> <main|all> — matching pids, minus this shell, its
# ancestors and interpreters.
function __gm_app_pids --argument-names pat mode
    set -l protected (__gm_protected)
    # fish globs have no [0-9] ranges (no match at all), so filter numerically.
    for p in /proc/*
        set -l pid (string replace -r '^/proc/' '' -- $p)
        string match -qr '^[0-9]+$' -- "$pid"; or continue
        contains -- $pid $protected; and continue
        test -r $p/cmdline; or continue
        set -l cmd (tr '\0' ' ' < $p/cmdline 2>/dev/null)
        test -n "$cmd"; or continue
        string match -rq -- "$pat" "$cmd"; or continue
        if test "$mode" = main; and string match -q -- '*--type=*' "$cmd"
            continue
        end
        __gm_shellish (string split -m1 ' ' -- "$cmd")[1]; and continue
        echo $pid
    end
end

# __gm_app_rss <pattern> — whole-app resident memory in MiB
function __gm_app_rss --argument-names pat
    set -l rss 0
    for p in (__gm_app_pids "$pat" all)
        set -l kb (awk '/^VmRSS:/{print $2}' /proc/$p/status 2>/dev/null)
        test -n "$kb"; and set rss (math "$rss + $kb")
    end
    math -s0 "$rss/1024"
end

function __gm_can_sudo
    test (id -u) = 0; and return 0
    command sudo -n true 2>/dev/null; and return 0
    if isatty stdin
        printf 'system units need root — sudo asks once now\n'
        command sudo -v; and return 0
    end
    return 1
end

function __gm_sudo_prefix
    test (id -u) = 0; and return 0
    if command sudo -n true 2>/dev/null
        printf 'sudo -n'
    else
        printf 'sudo'
    end
end

# ---- the command -----------------------------------------------------------

function gaming-mode --description 'park background services to free RAM while gaming'
    set -l state_dir "$HOME/.local/state/gaming-mode"
    set -l state_file "$state_dir/active"
    set -l started_file "$state_dir/started"

    # User-session units: stopped without root.
    set -l user_units jellyfin.service localsearch-3.service \
        evolution-source-registry.service evolution-calendar-factory.service \
        evolution-addressbook-factory.service evolution-alarm-notify.service \
        dayboard.service dayboard-web.service
    # System units: stopped with sudo. hermes-agent + hermes-dashboard are by far
    # the biggest pair (~0.9 GiB); --keep-agent leaves them up for chat mid-game.
    set -l system_units hermes-dashboard.service hermes-agent.service \
        docker.service syncthing.service
    # Deliberately untouched: pipewire/wireplumber (game audio), NetworkManager,
    # tailscaled (remote access), display-manager, gnome-session, systemd-oomd.

    set -l mode
    set -l dry 0
    set -l user_only 0
    set -l keep_agent 0
    set -l want_apps 0
    set -l relaunch 1
    set -l apps

    for arg in $argv
        switch $arg
            case on off status toggle
                set mode $arg
            case -h --help
                __gm_usage
                return 0
            case --dry-run
                set dry 1
            case --user-only
                set user_only 1
            case --keep-agent
                set keep_agent 1
            case --no-apps
                set relaunch 0
            case --apps
                set want_apps 1
                set apps discord hermes
            case '--apps=*'
                set want_apps 1
                set apps (string split , -- (string replace -- '--apps=' '' $arg))
            case '*'
                printf 'error: unknown argument: %s (try --help)\n' $arg >&2
                return 1
        end
    end

    test -n "$mode"; or begin
        __gm_usage
        return 0
    end

    for a in $apps
        contains -- $a discord hermes; and continue
        printf "error: unknown app '%s' (known: discord hermes)\n" $a >&2
        return 1
    end

    if test "$mode" = toggle
        if test -s $state_file
            set mode off
        else
            set mode on
        end
    end

    mkdir -p $state_dir

    switch $mode
        case on
            if test -s $state_file
                printf 'gaming mode is already ON (%s). Run "gaming-mode off" first.\n' $state_file
                return 0
            end
            # Recorded as we go: a crash or an interrupt halfway through still
            # leaves `off` with a complete list of what was actually stopped.
            test $dry -eq 1; or printf '' > $state_file

            set -l before_used (__gm_mem_used)
            set -l before_avail (__gm_mem_avail)
            printf 'RAM before : used %s MiB / %s MiB, available %s MiB, swap %s MiB\n' \
                $before_used (__gm_mem_total) $before_avail (__gm_swap_used)

            set -l n 0
            set -l freed 0

            for u in $user_units
                __gm_unit_active user $u; or continue
                set -l m (__gm_unit_mem user $u)
                if test $dry -eq 1
                    printf 'would stop   user/%s (~%s MiB)\n' $u $m
                    continue
                end
                if systemctl --user stop $u
                    printf 'unit:user:%s\n' $u >> $state_file
                    printf 'stopped      user/%s (~%s MiB)\n' $u $m
                    set n (math "$n + 1")
                    string match -qr '^[0-9]+$' -- "$m"; and set freed (math "$freed + $m")
                else
                    printf '! failed     user/%s\n' $u
                end
            end

            set -l sys_stop
            set -l sys_mem
            for u in $system_units
                if test $keep_agent -eq 1; and string match -q 'hermes-*' -- $u
                    printf 'kept         system/%s (--keep-agent)\n' $u
                    continue
                end
                __gm_unit_active system $u; or continue
                set -l m (__gm_unit_mem system $u)
                if test $dry -eq 1
                    if test $user_only -eq 1
                        printf 'would skip   system/%s (--user-only)\n' $u
                    else
                        printf 'would stop   system/%s (~%s MiB)\n' $u $m
                    end
                    continue
                end
                set -a sys_stop $u
                set -a sys_mem $m
            end

            if test $user_only -eq 1
                test (count $sys_stop) -gt 0
                and printf 'skipped      %s system unit(s) (--user-only)\n' (count $sys_stop)
            else if test (count $sys_stop) -gt 0
                if not __gm_can_sudo
                    printf '! system units left running: %s\n' "$sys_stop"
                else
                    set -l s (__gm_sudo_prefix)
                    test -n "$s"; and set s (string split ' ' -- "$s")
                    if $s systemctl stop $sys_stop
                        for i in (seq (count $sys_stop))
                            printf 'unit:system:%s\n' $sys_stop[$i] >> $state_file
                            printf 'stopped      system/%s (~%s MiB)\n' $sys_stop[$i] $sys_mem[$i]
                            set n (math "$n + 1")
                            string match -qr '^[0-9]+$' -- "$sys_mem[$i]"
                            and set freed (math "$freed + $sys_mem[$i]")
                        end
                    else
                        printf '! failed to stop: %s\n' "$sys_stop" >&2
                    end
                end
            end

            if test $want_apps -eq 1
                for a in $apps
                    set -l label (__gm_app_label $a)
                    set -l pat (__gm_app_pattern $a)
                    set -l pids (__gm_app_pids $pat main)
                    if test (count $pids) -eq 0
                        printf 'not running  %s\n' $label
                        continue
                    end
                    if test $dry -eq 1
                        printf 'would close  %s (main pid %s)\n' $label "$pids"
                        continue
                    end
                    set -l m (__gm_app_rss $pat)
                    for p in $pids
                        kill -TERM $p 2>/dev/null
                    end
                    for i in (seq 1 40) # up to 8 s for a clean exit
                        set -l alive 0
                        for p in $pids
                            test -d /proc/$p; and set alive 1
                        end
                        test $alive -eq 1; or break
                        sleep 0.2
                    end
                    for p in $pids
                        test -d /proc/$p; and kill -KILL $p 2>/dev/null
                    end
                    for p in (__gm_app_pids $pat all) # orphaned children
                        test -d /proc/$p; and kill -TERM $p 2>/dev/null
                    end
                    printf 'app:%s\n' $a >> $state_file
                    printf 'closed       %s (~%s MiB)\n' $label $m
                    set n (math "$n + 1")
                    set freed (math "$freed + $m")
                end
            end

            if test $dry -eq 1
                printf 'dry run — nothing changed.\n'
                return 0
            end

            printf 'started=%s\n' (date -Is) > $started_file
            printf 'before_used=%s\n' $before_used >> $started_file
            printf 'before_avail=%s\n' $before_avail >> $started_file
            printf 'rss_freed=%s\n' $freed >> $started_file

            sleep 2 # let the kernel hand the pages back before measuring
            set -l after_used (__gm_mem_used)
            set -l after_avail (__gm_mem_avail)
            printf '\n'
            printf 'parked %s thing(s), ~%s MiB of RSS\n' $n $freed
            printf 'RAM after  : used %s MiB, available %s MiB  (delta used -%s MiB, available +%s MiB)\n' \
                $after_used $after_avail \
                (math "$before_used - $after_used") \
                (math "$after_avail - $before_avail")
            printf 'back to normal: gaming-mode off\n'

        case off
            if not test -s $state_file
                printf 'gaming mode is not on (no %s). Nothing to do.\n' $state_file
                rm -f $state_file $started_file
                return 0
            end

            set -l rec (cat $state_file)
            set -l sys_start
            set -l apps_back
            # reverse order: what was stopped last comes back first
            for line in $rec[-1..1]
                switch $line
                    case 'unit:user:*'
                        set -l u (string replace -- 'unit:user:' '' $line)
                        if test $dry -eq 1
                            printf 'would start  user/%s\n' $u
                        else if systemctl --user start $u 2>/dev/null
                            printf 'started      user/%s\n' $u
                        else
                            printf '! failed     user/%s\n' $u >&2
                        end
                    case 'unit:system:*'
                        set -a sys_start (string replace -- 'unit:system:' '' $line)
                    case 'app:*'
                        set -a apps_back (string replace -- 'app:' '' $line)
                end
            end

            if test (count $sys_start) -gt 0
                if test $dry -eq 1
                    printf 'would start  system: %s\n' "$sys_start"
                else if not __gm_can_sudo
                    printf '! cannot start system units without sudo: %s (state file kept)\n' \
                        "$sys_start" >&2
                    return 1
                else
                    set -l s (__gm_sudo_prefix)
                    test -n "$s"; and set s (string split ' ' -- "$s")
                    if $s systemctl start $sys_start
                        for u in $sys_start
                            printf 'started      system/%s\n' $u
                        end
                    else
                        printf '! failed to start: %s (state file kept)\n' "$sys_start" >&2
                        return 1
                    end
                end
            end

            if test (count $apps_back) -gt 0
                if test $relaunch -eq 0
                    printf 'apps left closed: %s (--no-apps)\n' "$apps_back"
                else if test $dry -eq 1
                    for a in $apps_back
                        printf 'would relaunch %s\n' (__gm_app_label $a)
                    end
                else
                    for a in $apps_back
                        if setsid -f (__gm_app_launch $a) >/dev/null 2>&1
                            printf 'relaunched   %s\n' (__gm_app_label $a)
                        else
                            printf '! could not relaunch %s — start it yourself\n' (__gm_app_label $a) >&2
                        end
                    end
                end
            end

            if test $dry -eq 1
                printf 'dry run — state file untouched.\n'
                return 0
            end
            rm -f $state_file $started_file
            printf '\nRAM after  : used %s MiB, available %s MiB, swap %s MiB\n' \
                (__gm_mem_used) (__gm_mem_avail) (__gm_swap_used)
            printf 'services restored — normal mode.\n'

        case status
            if test -s $state_file
                printf 'gaming mode: ON\n'
                if test -r $started_file
                    printf '  since %s, parked RSS %s MiB\n' \
                        (awk -F= '/^started=/{print $2}' $started_file) \
                        (awk -F= '/^rss_freed=/{print $2}' $started_file)
                end
            else
                printf 'gaming mode: off\n'
            end
            printf '\nRAM: used %s / %s MiB   available %s MiB   swap %s MiB\n' \
                (__gm_mem_used) (__gm_mem_total) (__gm_mem_avail) (__gm_swap_used)
            printf '\n%-38s %-10s %10s\n' UNIT STATE MEM
            for u in $user_units
                set -l st stopped
                __gm_unit_active user $u; and set st active
                printf '%-38s %-10s %10s MiB\n' "user/$u" $st (__gm_unit_mem user $u)
            end
            for u in $system_units
                set -l st stopped
                __gm_unit_active system $u; and set st active
                printf '%-38s %-10s %10s MiB\n' "system/$u" $st (__gm_unit_mem system $u)
            end
            printf '\n'
            for a in discord hermes
                set -l pids (__gm_app_pids (__gm_app_pattern $a) main)
                if test (count $pids) -gt 0
                    printf '%-38s %-10s %10s MiB\n' "app/"(__gm_app_label $a) running (__gm_app_rss (__gm_app_pattern $a))
                else
                    printf '%-38s %-10s %10s\n' "app/"(__gm_app_label $a) stopped '-'
                end
            end
    end
end
