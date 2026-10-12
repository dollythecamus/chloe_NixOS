# Mission-control desktop implementation plan

Prepared: 2026-10-12. Scope: `chloe-laptop-sway-prototype` on the daily-use machine.
This is an execution plan, not implementation or activation approval.

Read alongside [the feature roadmap](mission-control-desktop-roadmap.md) and
[the design contract](mission-control-design.md). The roadmap defines F01–F18;
this document specifies their delivery order, concrete steps and acceptance gates.

## 1. Baseline and execution rules

### Verified starting point

- Repository sidebar revision `7c9645d` is built, but the running panel/bindings
  still lack its text command panes and new home route.
- Baseline test command was rerun for this plan: 33 tests passed.
- `swayidle.service` is inactive with `ConditionResult=no`; the previous audit
  showed `WAYLAND_DISPLAY` missing at its start. NetworkManager applet is failed.
- Home Manager's Sway `systemd.enable` evaluates to false. The installed
  `/etc/sway/config.d/nixos.conf` contains environment imports and Sway target
  startup/shutdown commands. Investigate the interaction; do not blindly add
  another independent startup script or assume one restart solves it.
- Existing backends/tools include BlueZ/Blueman, NetworkManager/nmtui,
  PipeWire/pavucontrol, Dunst, grim/slurp, wl-clipboard, playerctl, TLP,
  Yazi/Nautilus, CUPS/simple-scan, keyring and portal services.
- Availability of shortlisted packages does not establish feature compatibility
  or completed hardware tests. Recheck the pin when implementation starts.

### Ownership and scope

1. The agent inspects, writes declarative configuration, tests, builds and commits.
   The operator selects devices/accounts/policies, enters credentials directly in
   trusted UI, reviews disruptive actions and performs system activation.
2. Keep changes in prototype-only imports. Do not alter shared GPU, login,
   power/sleep or Niri/Plasma behavior without a separately reviewed reason.
3. Work in small vertical slices: one usable feature, including return/error paths,
   tests and documentation, before starting the next. Do not build a new generic
   desktop framework, binding generator or custom TUI suite in advance.
4. Preserve unrelated git edits. Stage explicit paths only; inspect staged content.
   Separate feature code from unrelated dependency/flake updates.
5. Track each item as `planned`, `in progress`, `built`, `installed`, `accepted`,
   `blocked` or `explicitly deferred`. A mock, fixture, successful build or empty
   device list cannot substitute for an unperformed real-device acceptance test.
6. Accessibility is a baseline requirement. An actual access need moves F16 forward;
   its later backlog position does not license inaccessible controls elsewhere.

## 2. Repeat this delivery loop for every feature

1. **Inspect:** refresh source/live state, relevant services, package versions,
   upstream CLI/API contracts and device capabilities. Determine what already works.
2. **Define the task:** write the normal keyboard sequence, its return route,
   expected state/feedback, unavailable state and any confirmation required.
3. **Choose the smallest component:** reuse an installed backend/TUI when it can
   perform the task. Prototype it in a normal themed terminal before integration.
4. **Allocate keys:** inspect all effective Sway bindings, including defaults/modes,
   and check US/BR layouts. Preserve existing keys, especially Super+B/T/N/M/F/F1.
   Use one small, searchable system-command menu where infrequent actions would
   otherwise produce excessive global shortcuts. Reserve no speculative keys.
5. **Write a failing regression:** test one new behavior at a time. Use stdlib
   fixtures/stubs for dispatch and unsafe edge cases; identify these as tests,
   never as real telemetry. Then implement the smallest passing change.
6. **Integrate:** keep reads and writes separate. EWW remains a read-only,
   non-focusable command/readout surface. Use validated stable IDs for actions,
   never truncated names, notification text, file labels or raw menu selections.
   Pass arguments as arrays; do not construct/evaluate shell commands from data.
7. **Make it discoverable:** update `home/sway.nix`, controller routes, any necessary
   Yuck/SCSS and `keys.txt` together. Add contextual hints and a status/home route.
   Keep routine controls keyboard-first; label any approved GUI fallback.
8. **Verify:** run focused/full tests, an actual normal-task/return-path smoke,
   failure tests and compact light/dark previews. Use an isolated scratch HOME/config
   under `$TMPDIR`; snapshot the installed panel and relevant audio/network state.
   Put exact preview-daemon shutdown and installed-window restoration in `finally`,
   then read them back. Isolate Kitty remote-colour dispatch or snapshot/restore
   affected terminals. Check expanded mode when affected; assert rendered colours,
   bounded text, focus/work-area safety and no poll writes or accidental state changes.
9. **Build and inspect:** build the prototype, then compare generated Home Manager
   files/bindings against source. Check Niri/Plasma evaluation when changing shared
   imports or conditions; a prototype build alone does not prove other outputs safe.
10. **Review and commit:** perform independent review for functional changes; commit
    only verified scoped paths and update the roadmap/help/evidence record.
11. **Install deliberately:** describe the generation/service changes and rollback
    before the operator activates. Recheck installed files, services and live IPC.
12. **Accept in daily use:** operator verifies physical ergonomics and real device
    behavior. Record friction and fix it before calling the feature accepted.

Canonical commands, executed by the agent from `~/nixos` during implementation:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s home/tests -v
bash -n home/dotfiles/config/mission-control/control.sh
git diff --check
nixos-rebuild build --flake .#chloe-laptop-sway-prototype
```

These are future implementation gates, not commands to activate the system now.
No `switch`, reboot, device pairing, network change, microphone unmute or storage
mount is part of an unattended verification pass.

### Likely edit locations

- `home/sway.nix`: prototype packages, bindings and session-specific services.
- `home/dotfiles/config/mission-control/control.sh`: explicit allowlisted commands.
- `widgets.py` / `status.py`: small bounded adapters/readouts where appropriate.
- `eww.yuck` / `eww.scss`: only necessary text views and their palette/layout.
- `keys.txt`: exact installed controls, not aspirational shortcuts.
- `home/tests/`: regression and isolated integration tests.
- `docs/`: acceptance evidence, roadmap state and component decisions.

Add a small helper or prototype-only Nix file when a concrete feature needs it;
do not split the project into a large framework merely to prepare for future work.

## 3. Phase A — make the current desktop reliable

### A1. Capture a reproducible session baseline

1. Read git status, live Sway config/output/input state and installed HM files.
2. Record only relevant user-manager variables, target/service properties and
   start-time journals. Do not dump arbitrary environment variables or secrets.
3. Compare the actual Sway wrapper, included `nixos.conf`, HM startup settings and
   generated unit dependencies. Identify the owner of environment import, target
   startup, authentication-agent startup and shutdown cleanup.
4. Record current window IDs/layouts, panel mode/theme and known-good rollback
   generation before any in-session tests. Keep private window titles out of logs.

**Exit gate:** the login/startup sequence is documented from real evidence, with
one testable hypothesis for the skipped idle service, not a collection of guesses.

### A2. Fix session environment/lifecycle sequencing

1. Reproduce the missing-environment/skipped-service condition in an isolated
   test/session where practical. Add a regression for the ordering being changed.
2. Ensure required Wayland/Sway variables reach both systemd-user and D-Bus
   activation before graphical dependent services are started.
3. Prefer the supported Sway/Home Manager integration if it can own this sequence
   once. Reconcile the existing NixOS include; do not enable competing startup
   owners. If the supported integration cannot express the required order, use a
   small documented session-scoped unit/helper rather than global environment hacks.
4. Tie services to the actual Sway session lifecycle so they do not leak across
   logout, fallback sessions or repeated config reloads.
5. Build/inspect generated units, imports and effective Sway startup commands.
6. After reviewed activation, test a fresh Sway login and a clean session exit;
   confirm the idle service starts with the right environment, starts once and
   stops with its owning session. Test that a config reload creates no duplicates.

**Exit gate:** fresh-login evidence proves correct lifecycle. A manual restart of
the skipped unit is diagnostic only, not acceptance of the declarative fix.

### A3. Restore idle/lock behavior and verify authentication

1. Keep the current no-suspend policy. Use isolated/temporarily shortened idle
   timings for testing, then restore declared normal timings.
2. Verify display blanking, wake by input, idle lock and the manual lock shortcut.
   The operator performs unlock/authentication; the agent never asks for passwords.
3. Verify the lock path used by logind/lid-close signals; test actual lid behavior
   only with the operator present and unsaved work protected.
4. Check whether a Polkit authentication agent is registered. If missing, select
   an available package at the current pin and declare one session-scoped agent.
5. Exercise a harmless authentication request and cancellation with operator
   interaction; verify there is neither a missing prompt nor a duplicate agent.
   Confirm secret-service/keyring availability separately.

**Exit gate:** automatic/manual lock and appropriate authentication prompts work
in a fresh session. Suspend/resume repair remains a separate project, not a new
menu entry disguised as a standard desktop feature.

### A4. Clean redundant applet startup and verify portals

1. Determine whether nm-applet serves any workflow not covered by nmtui/sidebar.
   Recommended default is to disable this redundant applet in the prototype only
   when no required agent/action depends on it; retain Niri/Plasma behavior.
2. If retained, fix its environment/lifecycle and document its purpose without
   introducing an unused permanent tray.
3. Test an actual application file picker and browser screen sharing using a
   controlled test window/output. Confirm routing to the correct portal backend,
   permission/cancel behavior, stop behavior and useful failure feedback.
4. Keep existing GTK/wlroots/keyring providers when they serve distinct roles;
   do not replace the plumbing solely to simplify a service list.

**Exit gate:** no unexplained failed desktop unit remains; file-picker/share flows
are proven, not inferred from active portal service names.

### A5. Install and accept the terminal-first baseline

1. Review the full generation/dependency diff, including updates unrelated to UI.
2. Build the foundation changes and existing sidebar revision; inspect generated
   config and preserve a known-good boot/login recovery generation.
3. Present the activation effect and rollback before the operator activates the
   selected generation. Avoid repeated activations when one reviewed baseline suffices.
4. Compare installed files with source; verify actual Super+N/M, home, theme,
   width, hide/show, nmtui and media-key behavior in the live session.
5. Capture compact light/dark and affected expanded views; keep workspace context,
   4:3 compact work area and focus safe. Verify theme reload repairs actual colours.
6. Establish measured idle CPU/RSS and polling baseline for later comparisons.

**Exit gate:** the source/built/installed distinction is resolved and the operator
accepts a reliable keyboard-first baseline before more widgets are added.

## 4. Phase B — everyday desktop essentials

### F01 — Bluetooth manager

1. Query adapters, rfkill state, paired/connected devices and exposed battery data;
   distinguish no adapter, blocked, powered off and backend error states.
2. Evaluate `bluetuith` and `bluetui` against current BlueZ and the actual keyboard
   workflow. Test pairing-agent support, device selection, trust/untrust, removal,
   reconnect, cancellation and clean exit; verify those actions are keyboard reachable.
3. Select one manager. Keep Blueman as an explicit fallback for unsupported flows;
   do not add both TUIs as permanent components without a demonstrated need.
4. Declare its prototype package/launcher. Add a compact Bluetooth readout and
   visible open/manage command; device selection/actions belong in the focused TUI.
5. Add explicit powered-state/connect/disconnect commands only if the selected
   manager cannot already serve the needed task. Scan on demand with a stop path;
   never scan continually from an EWW poll.
6. Test bounded names, missing batteries, multiple adapters and stale device IDs.
   Known/paired identity, not a displayed nickname, determines action targets.
7. With the operator choosing a test device, exercise pair/connect/disconnect,
   deliberate trust/untrust, reconnect after logout, refusal/cancel and radio-off.
   Test removal first with a fixture/test pairing and demonstrate its cancel path;
   remove a real pairing only with explicit operator approval. The operator handles
   passkeys/confirmation, and the UI must state that removal forgets the pairing.

**Acceptance:** manage an actual chosen peripheral without the mouse, including
keyboard trust/removal access and cancellation, see truthful state, exit back to work,
and leave no unintended discovery/pairing process running. Real removal acceptance
remains blocked until an approved test pairing is available; a fixture is not proof.
**Dependencies:** Phase A; F07 later verifies Bluetooth-headset audio profiles.
**Rollback:** disable the new readout/launcher and revert its feature commit;
BlueZ/Blueman and existing pairings remain intact.

### F02 — Notification centre and Do Not Disturb

1. Inspect Dunst's installed config and real history/action capabilities.
   Reuse `dunstctl history`, `count`, `is-paused` and documented action/history
   commands rather than starting a second notification daemon.
2. Add a bounded status indicator and keyboard commands for DND, dismiss,
   history/replay and notification actions. DND state must be visible.
3. Render/select history in a small terminal view or keyboard menu using numeric
   notification IDs. Treat titles, bodies, markup and URLs as untrusted data.
4. Define privacy rules: no extra persistent copy of notification bodies; avoid
   private-message text in general shell logs. Escape control sequences/markup.
5. Test empty history, DND waiting counts, actionless/expired notifications,
   malformed text, daemon restart and action cancellation.
6. Use clearly labeled test notifications to verify arrival, suppression, replay,
   dismissal and a safe action. Verify an action requiring a context menu can be
   reached from the keyboard or document the necessary approved fallback.

**Acceptance:** inspect and act on a notification, toggle DND and return to work
without losing focus unpredictably or hiding that notifications are paused.
**Rollback:** remove only the new commands/view; the existing Dunst service remains.

### F03 — Screenshots

1. Audit existing Print-family bindings and choose capture/save/copy combinations
   that remain usable in both keyboard layouts. Choose the output directory and
   retention policy; no silent cloud upload or arbitrary attachment processing.
2. Implement a small helper using existing grim/slurp and wl-copy: selected area,
   selected/current output and focused-window geometry from Sway IPC.
3. Handle cancellation before writing/copying. Use collision-safe filenames and
   quote/validate paths and geometry; do not interpolate window titles into shell.
4. Make save and clipboard effects explicit. Report completion/failure without
   depending on an unavailable `notify-send` binary; declare a notification client
   only if the existing command/control route cannot provide feedback.
5. Test negative output coordinates, scaling, floating/fullscreen windows, missing
   focus, unwritable directory, filename collision and unavailable clipboard.
6. Capture known test windows, verify image dimensions/content, confirm area cancel
   produces no file, and test more than one display when hardware is available.

**Acceptance:** each advertised capture route produces the correct image and clear
feedback; cancellation has no output. Screen recording is explicitly outside this
first slice, not silently counted as implemented.
**Dependencies:** F02 for richer feedback, F06 for later multi-output acceptance.

### F04 — Clipboard history

1. Before enabling anything, obtain the operator's retention/privacy decision:
   session-only versus persistent, entry limits, images, startup behavior and pause.
   Recommended starting point is bounded, session-only storage.
2. Inspect cliphist's current interface and supported database-location setting.
   Place volatile data in a private runtime directory if supported; do not assume
   its default cache path is session-only. Clear appropriately at session end.
3. Declare the smallest required watcher/service, tied to the repaired Sway
   lifecycle, only after consent. Make pause stop capture, not merely hide a picker.
4. Add a searchable keyboard picker for text/images using item IDs. Decode/copy
   with argument arrays; never execute clipboard content or display raw escapes.
5. Add visible pause, clear-entry/all and open commands. Document that password
   hints/exclusion filters cannot guarantee every copied secret is excluded.
6. Test Unicode/multiline content, duplicates, images, cancellation, size/count
   limits, watcher restart, pause, deletion and runtime-directory cleanup using
   dummy data—not real passwords or private screenshots.

**Acceptance:** retrieve text/image from approved history, pause capture and clear
it; retention matches the chosen policy and cancellation leaves the clipboard alone.
**Rollback:** stop/disable the watcher and clear its approved store; wl-copy/paste
continue working without a history manager.

### F05 — Session/power menu

1. Reuse Wofi's keyboard menu mode or a small terminal menu; map fixed labels to
   an internal allowlist, not arbitrary commands supplied by the menu/user.
2. Expose lock, logout, reboot and power-off. Omit ordinary suspend/hibernate
   actions unless they separately pass this machine's power/recovery gate.
3. Require explicit confirmation for logout/reboot/shutdown; default to cancel,
   show the exact effect and do not accept an accidental Return as confirmation.
4. Ensure the operator can cancel, return focus and launch lock directly. Verify
   the backend's permissions rather than hiding privilege failures.
5. Unit-test exact dispatch with stubs and every cancellation/error branch. The
   agent does not log out, reboot or power off the daily session to prove dispatch.
6. The operator schedules an actual clean-session exit/reboot/shutdown test after
   saving work; verify the subsequent login and recovery path.

**Acceptance:** safe keyboard menu, tested cancel/lock and operator-verified real
session actions. Stubbed shutdown tests remain labeled as such.
**Dependencies:** Phase A authentication/lifecycle; no sleep-policy changes.

**Phase B checkpoint:** complete a keyboard-only daily task sequence covering
Bluetooth, notifications, screenshots, clipboard and session commands. Record
awkward keys/density/focus behavior and revise before moving to peripherals.

## 5. Phase C — peripherals and devices

### F06 — Displays and hotplug profiles

1. Record real output IDs/modes/scales/positions and the operator's useful layouts.
   Define extend/external-only/docked presets for tested combinations; inspect the
   pinned compositor's actual mirror capability before advertising a mirror preset.
   Do not assume native mirroring: upstream still tracks it as an open request.[1]
2. Solve sidebar output selection by stable built-in output identity where the
   pinned EWW interface supports it; do not rely on monitor index 0 after hotplug.
3. Prototype native extend/output presets with explicit revert/timeout behavior,
   nonzero/negative positions and safe fallback. Matching modes or overlapping output
   coordinates must not be treated as reliable mirroring or pass mirror acceptance.
4. If native mirroring is unavailable, evaluate a small existing client rather than
   changing compositor: `wl-mirror` mirrors onto a client surface that can be
   fullscreened on the destination output.[2] Its package is available in the audited
   pin, but verify current protocol/renderer compatibility, output placement and
   actual behavior on this NVIDIA machine before declaring it usable.
5. Implement mirror start/stop/revert with one session-owned client, no recursive
   self-capture and cleanup on output loss/session exit. Select full-output versus
   presentation-region capture explicitly; share controlled test content. Verify
   scale/aspect/rotation, focus and fullscreen interactions. If the client fails,
   record mirroring as blocked; extend-only success does not satisfy that workflow.
6. Evaluate kanshi for automatic known-output profiles and wdisplays as a labeled
   native-layout fallback, not a substitute for a mirror client. Coordinate explicit
   mirror-client startup/cleanup with profile changes; prevent duplicate clients and
   competing owners that repeatedly rewrite the same output layout.
7. Add a keyboard selector/status for profiles; persist the approved preference
   declaratively, not a pile of unexplained runtime swaymsg adjustments. Distinguish
   native layout state from an active mirror-client process in the readout.
8. Test plug/unplug, failed/unsupported mode, mirror stop/restart, lid/display loss,
   workspace migration, fullscreen, scaled screenshots and panel reservation. Do not
   blank the only usable display or move private content to an external output unattended.

**Acceptance:** apply/revert a real native layout and hotplug without losing windows,
focus or recovery; built-in compact area remains correct and other outputs usable.
Advertised mirroring must visibly reproduce the selected source and stop/revert
cleanly on real hardware, or remain explicitly blocked rather than counted complete.
**Rollback:** stop the exact mirror client, select the verified built-in fallback
and disable the new profile owner; verify no capture/client process remains.

### F07 — Audio devices and application mixer

1. Inventory sinks/sources/streams/profiles and the actual PipeWire/Pulse socket
   arrangement. Inspect `wiremix` and `pulsemixer` capabilities against that setup.
2. Select a keyboard manager for supported output/input selection, per-app volume
   and routing. Keep pavucontrol fallback for functionality the TUI cannot provide.
3. Add launcher/status and safe default-device controls; retain existing capped
   volume/media-key dispatch and read-only ASCII meters.
4. Test disappeared devices/streams, no microphone, reconnect, muted state,
   application exit, backend failure and numeric/device-ID validation.
5. Operator tests speakers/headphones and Bluetooth headset profile switching,
   with explicit consent before unmuting an input. Do not start recording to
   demonstrate a readout or raise sound unexpectedly.

**Acceptance:** choose a real output/input, adjust/reroute a test application's
stream and recover from device removal using the keyboard; unsupported profile
operations have a truthful, accessible fallback.
**Dependencies:** Phase A; F01 before accepting headset integration.

### F08 — Brightness, battery and idle inhibition

1. Read the actual backlight/battery interfaces and supported estimates. Mark
   unavailable/unknown estimates rather than inventing time remaining.
2. Add brightness percentage/set commands and update the readout after media-key
   changes. Validate numeric bounds; provide recovery without a black-screen trap.
3. Add explicit monitor-off using the existing compositor; verify input wakes it.
4. Implement temporary keep-awake through a supported inhibitor mechanism after
   checking its real interaction with swayidle/logind. Prefer a timed, session-owned
   inhibitor process; do not stop/restart arbitrary user services as a shortcut.
5. Clearly state what is inhibited. Lock must remain independently available;
   cancellation, expiry and session exit release the inhibitor. Do not silently
   disable security locking under the name of a display-only presentation mode.
6. Preserve TLP. Add no competing power-profile daemon or suspend policy.
7. Test brightness endpoints, external/no-backlight output, battery removal/data
   failure, inhibitor expiry/cancel/reload/logout and actual idle behavior.

**Acceptance:** truthful brightness/battery state and a visible, reversible
keep-awake mode whose lock/display effects match the chosen policy.
**Dependencies:** accepted idle lifecycle from Phase A; F06 for multi-output behavior.

### F09 — Media transport

1. Inspect playerctl/MPRIS players and their supported actions. Define whether
   commands target the last active player or an explicitly selected player.
2. Add media-key/keyboard play-pause/previous/next actions with a keyboard player
   selector; do not unexpectedly control another application's media.
3. Add a compact optional track readout, truncating/escaping external metadata.
   Use events or conservative polling; no permanent animated media surface.
4. Test no player, multiple players, unsupported actions, long/private metadata
   and player termination/restart. Test actual playback with chosen harmless media.

**Acceptance:** control the selected real player, change player and see truthful
state without unnecessary background activity or metadata logging.

### F10 — Removable storage

1. Inventory UDisks/GVfs activation and actual devices; distinguish an idle
   on-demand service from a failed service. Never identify an eject target by label.
2. Keep the first slice explicit: list, mount, open, unmount/eject. Obtain an
   automount decision before adding udiskie/automatic behavior; no policy by accident.
3. Select a small keyboard picker or existing device manager. Use stable device
   object IDs and validate removability/system-disk restrictions at action time.
4. Integrate file-manager opening and Polkit prompts. The operator enters any
   encrypted-volume passphrase directly in a trusted prompt; it never enters logs.
5. Handle busy volumes, unplug races, authorization failure and mounted encrypted
   volumes. Never force-unmount or eject the root/boot/system disk.
6. Test mocks first, then an operator-selected expendable USB device. Verify
   mount contents, normal unmount and disappearance only after successful eject.

**Acceptance:** manage a real removable device from the keyboard with clear busy/
error feedback and no accidental system-disk or automount action.
**Dependencies:** Phase A authentication; F13 improves the open-file workflow.

### F11 — VPN, wired and airplane controls

1. Inspect NetworkManager wired/VPN profiles and Hamachi/Haguichi roles separately.
   Use each owning manager/API; do not assume nmtui supports every VPN configuration.
2. Extend read-only status to active transport and VPN state. Preserve useful data
   on partial query failure; show unavailable sections instead of false empty state.
3. Add profile actions using UUIDs and existing manager entry points. Credential
   entry remains in that manager; no passwords in sidebar actions or command lines.
4. Ask for the airplane-mode policy: which WLAN/Bluetooth adapters, how prior
   radio states are restored, and what confirmation is needed while connected.
5. Test transport/VPN failure, stale UUID, multiple radios, wired-with-Wi-Fi-off,
   partial backend outage and cancellation. Test disconnections/radio changes only
   on an operator-approved connection; never cut the active agent/remote session.

**Acceptance:** manage the selected VPN/wired flow and deliberate airplane-mode
transition with correct recovery and truthful per-section state.
**Dependencies:** Phase A, F01 for coherent Bluetooth/all-radio presentation.

### F12 — Keyboard/input status

1. Inventory live input identities and active layout through Sway IPC. Use stable
   device identities, not translated layout names, for input actions.
2. Add a compact current-layout indicator reflecting actual keyboard switching;
   use supported input events or conservative polling after checking the pin.
3. Add discoverable layout selection, touchpad enable/disable, repeat-rate and
   repeat-delay access after checking supported Sway settings and units. Validate
   bounds and provide a reset to declared defaults. Keep persistent Home Manager
   defaults separate from explicit session toggles/input adjustments.
4. Audit the complete shortcut map on US and BR layouts, including screenshot
   keys, bracket volume keys, composition and Caps-as-Control behavior.
5. Test multiple keyboards, device hotplug, reload, layout-switch state, repeat
   rate/delay adjustment and reset, and recovery when the touchpad is disabled.
   Do not disable the only input route.

**Acceptance:** indicator follows real layout changes and every advertised key
remains usable; touchpad and repeat settings are reversible from the keyboard,
and approved persistent input defaults survive a fresh session.

**Phase C checkpoint:** use the machine with the actual monitor/headset/USB/input
combination. Re-test Phase B and measure service/resource changes against baseline.
Do not mark hardware-dependent checks passed when that hardware was unavailable.

## 6. Phase D — conveniences and desktop completeness

### F13 — Files, search and default applications

1. Choose Yazi as the initial keyboard file route, retaining Nautilus when drag/
   drop or GUI integration is useful. Add a shortcut without replacing all file apps.
2. Provide on-demand file/recent-item search over explicitly selected directories.
   Agree scope before indexing; avoid crawling private/huge project/cache trees.
3. Open selected files with the owning application using safe paths/argument arrays.
   Never treat filenames, desktop entries or search text as shell fragments.
4. Add a searchable settings/association entry point. Persist approved MIME/default
   choices in Home Manager, not edits to managed mimeapps symlinks.
5. Test spaces/Unicode, renamed/deleted files, large result sets, missing apps,
   cancellation, browser/protocol defaults and drag/drop fallback.

**Acceptance:** find/open a real selected file from the keyboard and persist an
approved application association without breaking existing browser handlers.

### F14 — Calendar/agenda

1. Deliver a local on-demand text month/date view first; no account or always-on
   service is needed to complete that portion.
2. Operator chooses calendar source, timezone and desired event exposure before
   adding agenda integration. Validate a maintained CLI/TUI or existing local
   calendar backend rather than inventing an account/storage system.
3. Add a keyboard launcher and optional bounded next-event readout; use explicit
   refresh and conservative caching. Do not print private event contents to logs.
4. Test month/year/leap transitions, all-day events, timezone changes, empty/offline
   source and stale cache. Test consented sample events, not fabricated live data.

**Acceptance:** correct month view and selected-source agenda with visible data
freshness; if no source is chosen, label agenda blocked/deferred, not implemented.

### F15 — Printers and scanners

1. Discover actual printers/scanners, CUPS jobs and authorization requirements.
   Running CUPS/simple-scan packages do not prove a driver or device works.
2. Add keyboard access to device/job status, selected-job cancellation and the
   scanner launcher. Reuse existing configuration tools where a custom TUI has
   no practical benefit; keep any GUI fallback explicit and keyboard reachable.
3. Declare drivers/discovery/scanning services only for a demonstrated device
   need, avoiding changes to network exposure merely to populate a widget.
4. Test no-device, offline printer, denied/cancelled job and scanner failure.
   The operator approves a physical test page/scan and any network discovery.

**Acceptance:** reach and manage a real device/job; unavailable hardware is a
recorded acceptance blocker, not proof from an empty list or mock.

### F16 — Accessibility

1. Determine concrete access needs before choosing tools; prioritize any required
   accommodation immediately rather than waiting for Phase D.
2. Verify keyboard traversal, readable focus feedback, discoverable cancel/home,
   US/BR ergonomics and actual sidebar/TUI legibility across all prior features.
3. Add reversible text-size/high-contrast preferences using existing palette/font
   mechanisms; keep compact geometry usable or provide an explicit accessible mode.
4. Verify screen-reader compatibility of selected TUI/GTK surfaces and configure
   an appropriate maintained reader only if requested. AT-SPI being active is not
   acceptance. Use controlled content for read-aloud/privacy tests.
5. Inspect compositor zoom capability at the pin; if unsupported, document a
   supported alternative or ask before larger compositor/tool changes.
6. Test enlarged text, long translated data, keyboard-only use, reader output and
   preference persistence/revert. Avoid an aesthetic-only choice that blocks access.

**Acceptance:** the operator's required access tasks work, with a clear fallback
for unsupported compositor features and no unverified accessibility claim.

### F17 — Background-app status / tray equivalent

1. List actual background-app tasks: reopen messaging windows, pause sync, inspect
   transfers, stop recording and access genuinely tray-only menus.
2. For each app, inspect supported window activation, CLI/API, desktop entry and
   notification actions. A window glyph is not a tray-action implementation.
3. Implement the smallest keyboard app-status/action list for supported tasks,
   using app IDs and explicit allowlisted actions; do not infer privileged actions
   from arbitrary StatusNotifier menu text or execute it as shell.
4. Prototype any remaining tray-only workflow with an existing accessible tray
   component. If it is truly required, ask for a documented design exception or
   discuss scope before writing a custom generic StatusNotifier/TUI bridge.
5. Test app restart, absent apps, vanished menu items, cancel/focus return and
   actual messaging/sync/recording controls with operator-selected test activity.

**Acceptance:** every identified necessary background action is reachable, either
through the keyboard list or a clearly approved accessible fallback. Unresolved
tray-only tasks remain blocked, not silently discarded to protect the aesthetic.

### F18 — System maintenance overview

1. Collect bounded read-only disk/battery/service warnings and resolved running/
   built generation identities. Do not mistake a store-name suffix or Nixpkgs
   revision for the repository's UI commit; label each identity accurately.
2. Add shortcuts to existing btop/systemctl/journal/status tools and a generation
   comparison entry point. Avoid a new high-frequency monitoring daemon.
3. Present package/update work as a review-first procedure: inspect working tree
   and lock diff, build, examine effects, then separate operator activation.
   No automatic flake edits, garbage collection or upgrades from a sidebar poll.
4. Agree alert thresholds/suppression so low-disk or failed services are useful,
   not a stream of false alarms. Redact sensitive environment/journal content.
5. Test missing telemetry, stale build link, failed/skipped units, full filesystem
   fixture and distinct source/built/installed labels; exercise real read-only views.

**Acceptance:** explain the actual machine/generation state and reach maintenance
work from the keyboard without silently changing packages or system state.

## 7. Final integration, adoption and rollback

### Integration pass

1. Audit all F01–F18 statuses; record explicit blockers/deferrals with reasons.
2. Run the full regression suite and inspect every advertised binding/controller
   route. Test no duplicate daemons, no orphan scan/watch/inhibitor processes, safe
   session teardown and truthful partial-failure/unavailable displays.
3. Exercise complete keyboard-only sequences: login/unlock, connect a peripheral,
   inspect notifications, capture/copy a screenshot, recover clipboard content,
   select media/audio, mount/eject approved media and cancel the session menu.
4. Inspect every new/affected compact light/dark view and expanded/accessibility
   mode. Test external outputs and real scaled layouts with the available hardware.
5. Measure process CPU/RSS and polling activity under comparable conditions:
   baseline, required services, then optional features individually. Agree resource
   budgets from measurements; optional heavy/indexing/scanning tasks stay off or
   on demand. Preserve CPU-load versus utilization labeling.
6. Use the result for ordinary work, creative apps and games; record actual friction
   before moving an item from installed to accepted. Do not equate a successful
   scripted demo with daily-use acceptance.

### Activation and rollback procedure for each milestone

1. Agent builds the selected prototype output and records exact source scope,
   generated files, dependency/service effects and the resulting store path.
2. Operator reviews activation choice and saves work. Preserve a known-good boot
   generation and reachable login/TTY recovery path; no garbage collection of it.
3. Only after reviewing the effects, the operator runs the selected activation
   command in her own terminal. A `switch` changes the running system/Home Manager;
   a `boot` installs a boot generation without proving the current session works.
   Decide which fits the particular changes; do not silently use one as a default.
4. Verify actual installed files, unit states and live Sway/EWW after activation.
   Verify a fresh login when lifecycle, agents, portals or startup changed.
5. For a UI-only fault, close the exact preview/new surface and restore the prior
   installed one. For a configuration regression, revert the scoped feature commit
   and rebuild; for login/session failure, use the preserved known-good generation.
6. Stop watchers/scans/inhibitors when rolling back and apply the chosen policy to
   their private stores. Preserve paired devices, personal data and unrelated work.

### Completion record

For every milestone, store: what changed, scoped commit, test results, build path,
installed state, operator/hardware acceptance, screenshots where useful, known
limitations and rollback. Never store credentials, clipboard contents, private
notification/event bodies or an unredacted desktop capture as general evidence.

The full roadmap is accepted only when its required workflows pass and any
optional deferrals/design exceptions are explicit operator decisions. Stop safely
at any accepted milestone and resume from this record later; no fixed deadline or
unattended background execution is implied by this plan.

## Sources

[1] https://github.com/swaywm/sway/issues/8644 — Sway upstream output mirroring issue
[2] https://github.com/Ferdi265/wl-mirror — wl-mirror upstream README
