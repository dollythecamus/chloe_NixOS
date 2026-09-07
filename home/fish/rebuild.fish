# rebuild — commit, verify, and switch the NixOS configuration.
#
#   rebuild                 prompt for a commit message if the flake is dirty,
#                           build without sudo to verify, then sudo-switch.
#   rebuild -m "msg"        same, with a non-interactive commit message.
#   rebuild --boot          install as default boot entry instead of switch
#                           (for kernel/initrd/bootloader changes).
#   rebuild --dry           verify with a build only; never touches the system.
#   rebuild -- <args>       extra args forwarded to nixos-rebuild.
#
# Design notes:
# - The sudo step is intentionally left interactive: you keep typing your own
#   password, so no credentials are stored anywhere.
# - `nixos-rebuild build` runs first WITHOUT sudo: evaluation/build errors
#   abort here and touch nothing on the live system. The derivation is cached,
#   so the switch afterwards reuses it.
# - Only tracked files are committed (`git add -u`); untracked files are shown
#   but never swept in automatically.
function rebuild --description 'commit, verify-build, and nixos-rebuild the flake'
    set -l flake ~/nixos
    set -l host (hostname)
    set -l mode switch
    set -l msg
    set -l dry no
    set -l extra

    set -l args $argv
    while set -q args[1]
        switch $args[1]
            case -m --message
                set msg $args[2]
                set -e args[2]
                set -e args[1]
            case --boot
                set mode boot
                set -e args[1]
            case --switch
                set mode switch
                set -e args[1]
            case --dry
                set dry yes
                set -e args[1]
            case -h --help
                echo 'usage: rebuild [-m MSG] [--boot] [--dry] [-- switch-args]'
                return 0
            case '*'
                set -a extra $args[1]
                set -e args[1]
        end
    end

    if not test -d $flake
        echo 'rebuild: flake directory not found:' $flake >&2
        return 1
    end
    pushd $flake >/dev/null

    # 1. commit local config changes (tracked files only)
    set -l changes (git status --porcelain -uno)
    if test (count $changes) -gt 0
        echo 'rebuild: committing tracked changes:'
        git status --short -uno
        set -l untracked (git ls-files --others --exclude-standard)
        if test (count $untracked) -gt 0
            echo 'rebuild: NOTE untracked files are NOT being committed:'
            printf '  %s\n' $untracked
        end
        if test -z "$msg"
            echo -n 'commit message: '
            read msg
        end
        if test -z "$msg"
            echo 'rebuild: empty commit message — aborting, nothing built.' >&2
            popd >/dev/null
            return 1
        end
        if not git add -u
            echo 'rebuild: git add failed.' >&2
            popd >/dev/null
            return 1
        end
        if not git commit -q -m "$msg"
            echo 'rebuild: commit failed.' >&2
            popd >/dev/null
            return 1
        end
        echo 'rebuild: committed (' (git rev-parse --short HEAD) ').'
    end

    # 2. verify: full evaluation + build, no privileges involved
    echo 'rebuild: verifying build (.' $host ') ...'
    if not nixos-rebuild build --flake ".#$host"
        echo 'rebuild: build FAILED — live system untouched.' >&2
        popd >/dev/null
        return 1
    end

    if test $dry = yes
        echo 'rebuild: --dry — build verified, system not changed.'
        popd >/dev/null
        return 0
    end

    # 3. privileged step — sudo will prompt for your password on this tty
    echo 'rebuild: running nixos-rebuild' $mode '— sudo password required'
    sudo nixos-rebuild $mode --flake ".#$host" $extra
    set -l rc $status
    popd >/dev/null

    if test $rc -eq 0
        echo
        if test $mode = boot
            echo 'rebuild: installed as boot entry — reboot to apply.'
        else
            echo 'rebuild: done. current system:'
            echo '  ' (readlink /run/current-system)
            echo '  (generations: sudo nix-env -p /nix/var/nix/profiles/system --list-generations)'
        end
    else
        echo 'rebuild: nixos-rebuild' $mode 'exited with status' $rc >&2
    end
    return $rc
end
