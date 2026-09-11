# stayawake — hold a systemd sleep+i-idle block inhibitor so the machine
# never idle-suspends and ignores the lid closing while ON.
#
#   stayawake         show status
#   stayawake on      start inhibiting (machine stays on: no idle suspend, no lid suspend)
#   stayawake off     stop inhibiting (normal swayidle/logind sleep behaviour resumes)
#   stayawake status  show state + the inhibitor line
#
# How it works:
# - ON starts a systemd --user transient unit that runs `systemd-inhibit
#   --what=sleep:idle --mode=block sleep infinity`. A `block` sleep inhibitor
#   is consulted by logind for BOTH the swayidle idle suspend timer and the
#   lid switch, so while it is held the machine cannot enter sleep.
# - Runs as the logged-in user (no sudo). logind checks user-held inhibitors
#   system-wide, so this also works when the command is issued remotely
#   (e.g. from Hermes over Discord) without a password prompt.
# - The unit is registered in the graphical user session's manager, which is
#   the session that stays awake.
#
# Driving it from Hermes (Discord): just call `stayawake on` / `stayawake off`.
function stayawake --description 'toggle the "keep machine on while away" sleep inhibitor'
    set -l unit stayawake
    set -l cmd status
    if set -q argv[1]
        set cmd $argv[1]
    end

    switch $cmd
        case on start enable
            if systemctl --user is-active --quiet $unit
                echo 'stayawake: already ON.'
            else
                systemd-run --user \
                    --unit=$unit \
                    --property='Description=stayawake: keep machine on (sleep inhibitor)' \
                    --collect \
                    systemd-inhibit \
                        --what=sleep:idle \
                        --who=stayawake \
                        --why='stayawake: keep machine on while away' \
                        --mode=block \
                        sleep infinity
                and echo 'stayawake: ON — machine will not suspend or sleep.'
                or echo 'stayawake: failed to start inhibitor.' >&2
            end

        case off stop disable
            if systemctl --user is-active --quiet $unit
                systemctl --user stop $unit
                echo 'stayawake: OFF — normal sleep behaviour resumed.'
            else
                echo 'stayawake: already OFF.'
            end

        case status '' '*'
            if systemctl --user is-active --quiet $unit
                echo 'stayawake: ON'
            else
                echo 'stayawake: OFF'
            end
            systemd-inhibit --list --no-legend 2>/dev/null | grep -i stayawake || true
    end
end