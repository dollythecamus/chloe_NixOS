# Mission-control design contract

Scope: `chloe-laptop-sway-prototype`, `home/sway.nix`, and
`home/dotfiles/config/mission-control/`. This shell is used on the operator's
daily machine. Aesthetic and keyboard ergonomics are acceptance requirements,
not polish to defer until after functional work.

Source brief: `~/Mind/projects/nixos-system/ricing a space mission control terminal.md`.
Engineering state and recovery notes: `~/wiki/concepts/nixos-mission-control-prototype.md`.
Read the brief before changing the shell; leave its personal-vault references intact.

## Priority order

1. Preserve working daily use, recovery, accessibility and truthful system state.
2. Preserve the terminal/ASCII identity and keyboard-first interaction.
3. Add functionality only when it fits those constraints.

A working control that contradicts the design is not finished. Do not silently
trade keyboard usability for a convenient mouse widget. Ask the operator before
making a deliberate exception or introducing a larger UI/framework.

## Shell language

- Monospace, text/ASCII rendering, compact technical readouts and restrained
  borders. Space-travel/retro-console identity comes from typography, hierarchy,
  tables and command vocabulary, not decorative animation.
- Default light mode: off-white/pink `#f6edec`, plum text `#481d32`, red/pink
  accent `#ae3158`. Alternate dark mode: magenta `#250c23`, text `#ffe9ef`,
  accent `#ff718f`. Keep both legible at the actual panel size.
- Use read-only tables and ASCII meters instead of graphical sliders, progress
  widgets, button grids, rounded cards or mouse-hover navigation.
- Keep the persistent workspace strip and a visible return route across views.
  Show context-specific commands next to the readout and keep Super+F1 available.
- Ordinary controls must work without a mouse. The EWW sidebar does not take
  focus: global Sway hotkeys select views and dispatch explicit actions.
- A terminal TUI is the default for network management. A GUI may remain a
  clearly labeled escape hatch when there is no implemented keyboard path
  (currently advanced audio routing via pavucontrol).
- Unrelated browsers/creative applications may retain their own styling.
  Do not force a shell redesign into every installed program.

## Layout and cost

- Built-in 1920x1080: 480 px compact sidebar, 1440x1080 left work area (4:3).
  Expanded mode is 720 px and intentionally changes that aspect ratio.
- One panel owner; no competing bar or tray. Do not add focusable/click-only
  controls to a non-focusable layer-shell panel.
- Bound text rows/names to fit compact mode without mouse scrolling. Non-ASCII
  names use an ASCII-escaped display before truncation/padding; original SSIDs
  and profile names stay unchanged in data and in NetworkManager's `nmtui`,
  which owns full lists and credential entry.
- Preserve conservative polling and cached network scans. Missing data is `--`,
  not a fabricated value. Read/poll paths must never modify system state.
- Pet and orbit programs remain optional, launchable/stoppable, not daemons.

## Keyboard contract

All controls below use Super (Windows key), except laptop media keys.

| Keys | Effect |
|---|---|
| Backspace | Return to status |
| N / M | Network / audio readout; restore a hidden sidebar |
| Shift+N | Open themed Kitty with `nmtui`; arrows, Tab, Enter and Esc navigate |
| Ctrl+N | Toggle Wi-Fi radio; turning it off disconnects Wi-Fi |
| [ / ] | Output volume - / + 5%; increase is capped at 100% |
| Shift+M | Toggle output mute |
| Ctrl+M | Toggle microphone mute |
| Shift+A | Advanced audio routing, explicit GUI fallback |
| T / B / F | Palette / sidebar width / sidebar visibility |
| F1 | Complete hotkey reference |

Media volume/mute and microphone-mute keys use the same controller actions.
The authoritative complete binding list is `home/dotfiles/config/mission-control/keys.txt`.

## Gate for every shell change

- [ ] Read this contract and the source brief; state any intentional exception.
- [ ] Demonstrate the normal task and return path using only keyboard commands.
- [ ] Inspect real compact-mode light/dark screenshots: typography, alignment,
      contrast, density, clipping and visible command hints. Build success alone
      does not prove design fit. Inspect expanded mode when affected.
- [ ] Keep workspace context, the reserved work area, theme state and focus safe.
- [ ] Add/run regressions for the changed behavior and design constraints:
      `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s home/tests -v`.
- [ ] Preview using an isolated scratch HOME/config; restore the installed panel
      and stop the preview daemon. Do not overwrite Home Manager symlinks.
- [ ] Build `nixos-rebuild build --flake .#chloe-laptop-sway-prototype` and inspect
      generated Home Manager files/bindings. A build is not activation.
- [ ] Report separately: automated/rendering evidence, operator UX acceptance,
      and installation state. Do not call the design accepted on the operator's behalf.

Do not toggle a live network/radio or unmute a microphone merely to demonstrate
controls. Exercise dispatch with regression tests or an isolated harness; leave
actual connection/recording changes to deliberate operator use. System activation
remains a separate, reviewed operator action.
