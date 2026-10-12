#!/usr/bin/env bash
# Session-only controller; no daemon and no global configuration mutation.
set -euo pipefail
config="${XDG_CONFIG_HOME:-$HOME/.config}/mission-control"
state="${XDG_STATE_HOME:-$HOME/.local/state}/mission-control"
mkdir -p "$state"
current=light
[[ -f "$state/theme" ]] && read -r current < "$state/theme"
[[ "$current" == dark ]] || current=light
case "${1:-}" in
  start)
    # `eww daemon` stays in the foreground; start it separately, then wait for
    # its IPC socket rather than racing the first `open`.
    if ! eww -c "$config" ping >/dev/null 2>&1; then
      eww -c "$config" daemon >/dev/null 2>&1 &
    fi
    for _ in {1..20}; do
      eww -c "$config" ping >/dev/null 2>&1 && break
      sleep 0.2
    done
    eww -c "$config" close-all || true
    eww -c "$config" open compact
    eww -c "$config" update "view=home" "dark=$([[ "$current" == dark ]] && printf true || printf false)"
    ;;
  theme)
    if [[ "$current" == light ]]; then current=dark; else current=light; fi
    printf '%s\n' "$current" > "$state/theme"
    eww -c "$config" update "dark=$([[ "$current" == dark ]] && printf true || printf false)"
    # The pinned EWW/GTK can update `dark` without repainting CSS on an
    # already-open panel. Reload reconstructs it from the current variable
    # values, preserving page/width; verified against rendered pixel colours.
    eww -c "$config" reload
    # Managed Kitty windows expose per-process sockets only to this user.
    # Unlike a static include, this also updates already-open terminals.
    if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
      for sock in "$XDG_RUNTIME_DIR"/mission-control-kitty-*; do
        [[ -S "$sock" ]] || continue
        kitty @ --to "unix:$sock" set-colors --all --configured "$config/kitty-$current.conf" || true
      done
    fi
    ;;
  expand)
    if eww -c "$config" active-windows | grep -q ': expanded$'; then
      eww -c "$config" close expanded
      eww -c "$config" open compact
    else
      eww -c "$config" close compact
      eww -c "$config" open expanded
    fi
    ;;
  toggle-visibility)
    if eww -c "$config" active-windows | grep -Eq ': (compact|expanded)$'; then
      eww -c "$config" close-all
    else
      eww -c "$config" open compact
      eww -c "$config" update "dark=$([[ "$current" == dark ]] && printf true || printf false)"
    fi
    ;;
  widget)
    case "${2:-}" in home|network|audio) ;; *) exit 2 ;; esac
    # A hotkey can restore a hidden sidebar before selecting its page.
    if ! eww -c "$config" active-windows | grep -Eq ': (compact|expanded)$'; then
      eww -c "$config" open compact
    fi
    eww -c "$config" update "view=$2" "dark=$([[ "$current" == dark ]] && printf true || printf false)"
    case "$2" in
      home) eww -c "$config" poll status || true ;;
      *) eww -c "$config" poll "$2" || true ;;
    esac
    ;;
  action)
    python3 "$config/widgets.py" action "${@:2}"
    case "${2:-}" in
      wifi-toggle|connect) eww -c "$config" poll network || true ;;
      *) eww -c "$config" poll audio || true ;;
    esac
    ;;
  screenshot)
    # F03: grim/slurp/wl-copy. Paths and geometry flow as separate arguments —
    # never interpolated into a shell string. Subscription feedback reports the
    # concrete effect; a slurp cancellation aborts before any write.
    exec python3 "$config/screenshots.py" "${@:2}"
    ;;
  clipboard)
    # F04: cliphist picker replacing the HM default binder. Bound store,
    # pause/clear as explicit allowlisted subcommands, never arbitrary input
    # re-executed. Single instance; the watcher lives with the session service.
    exec python3 "$config/clipboard.py" "${@:2}"
    ;;
  session)
    # F05: session/power menu. Backend actions and confirmation flow live in
    # the Python dispatcher; suspend/hibernate are deliberately absent.
    exec python3 "$config/session.py" "${@:2}"
    ;;
  layout)
    # F12: unsupported until identifier detection is wired live; exit-code 2.
    echo "layout: not yet implemented" >&2
    exit 2
    ;;
  storage)
    # F10: no silent automount; picker opens in a terminal in scope for now.
    exec bash "$0" terminal --class mission-storage --title mission-storage \
      "${pkgs.udiskie}/bin/udiskie" --notify
    ;;
  system)
    # F18: bounded read-only overview via widgets.py + terminal shortcuts.
    python3 "$config/widgets.py" system || true
    ;;
  terminal)
    exec kitty --config "$HOME/.config/kitty/kitty.conf" --config "$config/kitty-$current.conf" \
      --override allow_remote_control=socket-only \
      --override 'listen_on=unix:${XDG_RUNTIME_DIR}/mission-control-kitty' "${@:2}"
    ;;
  launcher)
    exec wofi --show drun --style "$config/wofi-$current.css"
    ;;
  keys)
    exec bash "$0" terminal --title mission-keys less "$config/keys.txt"
    ;;
  *) printf 'usage: %s {start|theme|expand|toggle-visibility|widget <home|network|audio>|action <name> [value]|screenshot <mode>|clipboard|session|storage|system|terminal|launcher|keys}\n' "$0" >&2; exit 2 ;;
esac
