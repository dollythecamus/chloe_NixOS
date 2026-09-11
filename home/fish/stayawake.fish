# stayawake — hold systemd inhibitor locks so the machine never idle-suspends
# and ignores the lid switch while ON.
#
#   stayawake         show status
#   stayawake on      start inhibiting (no idle suspend, lid switch ignored)
#   stayawake off     stop inhibiting (normal swayidle/logind sleep behaviour resumes)
#   stayawake status  show state + the inhibitor line
#
# How it works:
# - ON starts a systemd --user transient unit running:
#       systemd-inhibit --what=sleep:idle:handle-lid-switch --mode=block sleep infinity
# - TWO different lock kinds are needed, and this is the part that is easy to
#   get wrong:
#     * sleep:idle  — high-level locks. logind consults these for the swayidle
#       30-min suspend and for IdleAction, so the machine will not idle-suspend.
#     * handle-lid-switch — a LOW-LEVEL lock. logind's config default
#       LidSwitchIgnoreInhibited=yes means the lid switch IGNORES high-level
#       sleep inhibitors ("when logind is handling events by itself ... the lid
#       switch does not respect suspend blockers by default"). Only a low-level
#       handle-* lock, which is "always honored", suppresses the lid action.
#       Without it, closing the lid still suspends — which is exactly the bug
#       this function originally had.
# - Runs as the logged-in user (no sudo). logind checks user-held inhibitors
#   system-wide, so the host stays up for remote services (e.g. the Hermes
#   gateway answering prompts from Discord).
#
# Caveats worth knowing:
# - The unit is transient: it does NOT survive a reboot, and it dies if the
#   user session ends (screen lock is fine; logout/reboot is not). Re-run
#   `stayawake on` after either.
# - state: the transient unit is not enabled, so a fresh boot starts OFF.
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
                    --property='Description=stayawake: keep machine on (sleep + lid inhibitor)' \
                    --collect \
                    systemd-inhibit \
                        --what=sleep:idle:handle-lid-switch \
                        --who=stayawake \
                        --why='stayawake: keep machine on while away' \
                        --mode=block \
                        sleep infinity
                and echo 'stayawake: ON — idle suspend and lid-close suspend are both inhibited.'
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