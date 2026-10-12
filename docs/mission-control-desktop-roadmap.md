# Mission-control desktop feature roadmap

Audit: 2026-10-12. Scope: the Sway prototype on the daily-use machine.
This is an inventory and proposed implementation order, not permission to enable
all services or replace the desktop. Follow [the design contract](mission-control-design.md).
The [step-by-step implementation plan](mission-control-implementation-plan.md)
expands every backlog item into implementation, testing, acceptance and rollback work.

## Current state: source is not the running shell

- The repository includes the terminal-first sidebar revision `7c9645d`.
  The installed EWW panel does not yet contain its `net.status` command pane,
  and live Sway has no new return-to-status binding. Network/audio navigation
  exists in the older running configuration. Do not describe the revised
  keyboard workflow as installed merely because the source builds.
- Existing foundations: Sway workspaces/window management, EWW status/clock,
  Wofi launcher, Kitty, NetworkManager, PipeWire, brightness commands and a
  manual swaylock binding. Yazi and Nautilus are installed; browser/protocol
  defaults are declarative. GNOME keyring and GTK/wlroots portals are running.
- Bluetooth service is active, its queried controller is powered and unblocked,
  and Blueman is installed. The gap is a discoverable keyboard-first shell
  workflow, not a missing Bluetooth stack.
- Dunst is running and already has history and pause/DND controls through
  `dunstctl`; the gap is shell presentation and hotkeys, not a missing daemon.
- `grim`, `slurp`, `wl-clipboard`, `playerctl`, `udisksctl` and `simple-scan`
  are installed. Packages alone are not a complete desktop workflow.

## Foundation checks before feature work

1. **Restore reliable idle locking/display blanking.** No swayidle process was
   detected. Its enabled user service was skipped because `WAYLAND_DISPLAY`
   was absent at start. The user-manager environment now has the display/socket
   variables, so inspect session startup ordering and verify a fresh login;
   do not claim a permanent fix from restarting a skipped unit once. Manual
   swaylock is available, but automatic idle locking is not currently running.
2. **Verify privileged-action prompts.** Polkit daemon is running; no standard
   desktop authentication-agent process was detected. Verify the session has
   an agent and can present appropriate prompts without terminal workarounds.
   Keyring/secret-service availability is a separate concern.
3. **Resolve stale/failed applet startup.** The NetworkManager applet failed with
   `cannot open display` at login. The sidebar has no system tray. Decide whether
   to remove the redundant applet from this prototype or retain it for a real
   purpose after repairing lifecycle/environment ordering. Leave Niri/Plasma alone.
4. **Keep portal integration honest.** GTK/wlroots portals are active, but service
   state does not prove file-picker or screen-sharing behavior. Exercise those
   flows in the actual browser/creative applications without exposing private content.
5. **Install/test the already-built sidebar revision separately.** Review the
   current flake changes before activation; then check physical hotkeys and
   normal-task/return paths. This roadmap does not activate a generation.

## Feature backlog

Status means what was observed in the running system or repository, not an
assumption that an end-to-end workflow has passed acceptance.

| ID | Feature | Current status / missing part | Proposed shell experience | Priority |
|---|---|---|---|---|
| F01 | Bluetooth manager | BlueZ/Blueman present; no Sway sidebar view or dedicated binding | Adapter state, connected/known devices and battery when exposed; hotkey opens a TUI for pair/connect/disconnect/trust/remove. Scan only on demand. Blueman remains fallback. | P1 |
| F02 | Notification centre and DND | Dunst/history available; no integrated history, actions or pause indication | Compact unread/waiting indicator, keyboard history/replay/dismiss/actions and a visible DND toggle. Reuse Dunst rather than adding a second notification daemon. | P1 |
| F03 | Screenshots | grim/slurp installed; no relevant live Sway screenshot binding found | Hotkeys for selected area, output and focused-window capture; save/copy options with explicit destination and completion feedback. Recording is a later extension. | P1 |
| F04 | Clipboard history | wl-clipboard installed; no history manager found | Searchable keyboard picker for text/images; pause and clear controls. Decide retention/privacy before enabling; avoid persistent history by default and do not promise perfect secret detection. | P1 |
| F05 | Session/power menu | Manual lock and confirmed session exit exist; no unified menu | Searchable text command menu for lock/logout/reboot/power-off; confirmation for disruptive actions. No normal suspend command while resume is broken. | P1 |
| F06 | Displays and hotplug profiles | Built-in output configured; no kanshi/wdisplays found | Keyboard selection of extend/output/resolution/scale presets; mirror through a tested native capability or separate client such as wl-mirror, never overlapping-position assumptions. Automatic known-monitor profiles only after testing. Keep sidebar on built-in output and restore workspaces/focus safely. | P2 |
| F07 | Audio devices and application mixer | PipeWire/basic controls present; routing uses pavucontrol | Keyboard output/input selection, per-app levels/routing, mute and Bluetooth-headset profiles. Evaluate a TUI before building a custom mixer; retain pavucontrol fallback. | P2 |
| F08 | Brightness, battery and idle inhibition | Brightness keys, power alerts and TLP present; no unified controls; idle service needs repair | Brightness percentage, battery state/time where available, explicit display-off and temporary keep-awake controls with a visible indicator. Do not stack a competing power-profiles daemon on TLP without review. | P2 |
| F09 | Media transport | playerctl installed; no relevant live playerctl binding found | Play/pause/previous/next hotkeys, active-player choice and a bounded track readout. No forced always-on media animation. | P2 |
| F10 | Removable storage | udisksctl/GVfs available; UDisks unit was inactive without failure; no udiskie found | Device list, explicit mount/open/unmount/eject and clear busy/error feedback. UDisks may activate on demand; inactivity alone is not proof of failure. No silent automount policy. | P2 |
| F11 | VPN, wired and airplane controls | NetworkManager and Hamachi/Haguichi exist; sidebar focuses on Wi-Fi | Connection/VPN state and keyboard profile actions; explicit all-radio policy for airplane mode. Keep credential entry in the owning manager and protect the active connection during tests. | P2 |
| F12 | Keyboard/input status | US/BR switching and touchpad settings declared; no sidebar layout indicator | Current layout, keyboard switching/help, touchpad toggle and repeat-rate/settings access. Check shortcuts in both layouts before allocating new bindings. | P2 |
| F13 | Files, search and default applications | Yazi/Nautilus and selected MIME defaults exist; no unified shell route | File-manager shortcut, on-demand file search/recent files and a searchable settings/association entry point. Avoid mandatory indexing or forced restyling of file applications. | P3 |
| F14 | Calendar/agenda | Clock/date readout exists; no agenda view | On-demand text month/calendar and upcoming events. Integrate a calendar only after choosing its source; do not copy private events into shell logs. | P3 |
| F15 | Printers and scanners | CUPS active and simple-scan installed; no shell device/job workflow | Keyboard device/job/status entry points, cancel-job action and scanner launcher. Reuse existing managers where a custom TUI adds maintenance without value. | P3 |
| F16 | Accessibility | AT-SPI infrastructure is running; full usable workflows untested | Discoverable text sizing/contrast, screen-reader compatibility, zoom where supported and keyboard-only navigation. A specific accessibility need moves this ahead of optional features. | P3 |
| F17 | Background-app status / tray equivalent | No sidebar system tray; window glyphs are not tray controls | Audit which apps need persistent actions (messaging, sync, recording). Prefer a keyboard app-status/action list; discuss a conventional tray only if required workflows cannot otherwise be reached. | P3 |
| F18 | System maintenance overview | Telemetry and terminal tools exist; no shell maintenance entry point | Disk/battery/service warnings and running-versus-built generation status, with shortcuts to existing tools. Updates remain review-first and declarative, not an unattended shell button that rewrites the flake. | P3 |

## Implementation order

- **Phase A — reliability:** foundation checks, then activation/acceptance of the
  existing sidebar revision. Fix security/session lifecycle problems before
  layering more services onto the same startup race.
- **Phase B — everyday essentials:** F01–F05. Recommended first feature: Bluetooth,
  after idle/auth/session checks. Reuse BlueZ and prototype pairing/connection in
  an existing terminal manager before adding its readout.
- **Phase C — peripherals and devices:** F06–F12, one complete workflow at a time.
  Choose the order from actual daily friction (external monitor/headset/USB use).
- **Phase D — optional conveniences:** F13–F18 only when needed. Do not implement
  all optional features merely to imitate a full desktop suite.

## Component shortlist: available, not selected/installed

Package attributes were verified against the current prototype's pinned package
set: `bluetuith`, `bluetui`, `cliphist`, `kanshi`, `wdisplays`, `udiskie`,
`wiremix`, `pulsemixer`, `dunst` and `simple-scan` exist. This proves package
availability, not Bluetooth pairing-agent behavior, PipeWire routing support,
accessibility or fitness for this palette. Evaluate the needed workflow before
selecting a component. No package/service was added during this audit.

## Delivery rule for every feature

- One readable status surface plus discoverable keyboard commands; not every
  function needs a permanently visible widget or its own daemon.
- Keep the workspace strip and return route, compact 4:3 layout, light/dark
  palette, focus safety and conservative resource use.
- Reuse installed backends; distinguish backend absence from integration gaps.
- Add tests, exercise the real normal-task/return path and failure/unavailable
  state, inspect compact light/dark previews and build the prototype only.
- Pairing/authentication, clipboard retention, storage automount and disruptive
  session actions need explicit user decisions/interaction. Do not test them by
  silently changing real devices, saving secrets, mounting media or ending sessions.
- Record source/built/installed/accepted states separately. Installation and
  operator UX acceptance remain separate from writing a feature or passing a build.
