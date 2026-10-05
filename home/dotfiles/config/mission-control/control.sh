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
    eww -c "$config" update "dark=$([[ "$current" == dark ]] && printf true || printf false)"
    ;;
  theme)
    if [[ "$current" == light ]]; then current=dark; else current=light; fi
    printf '%s\n' "$current" > "$state/theme"
    eww -c "$config" update "dark=$([[ "$current" == dark ]] && printf true || printf false)"
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
  *) printf 'usage: %s {start|theme|expand|toggle-visibility|terminal|launcher|keys}\n' "$0" >&2; exit 2 ;;
esac
