# Project ledger — nixos host configuration

Updated: 2026-11-09 · session local-13fdd66d7ff6133d3c3b38b777c07f1ff47ce13e1c8be6dfb590623ff153e4d9 · owner default
Next review: after the switch (the tailnet-IP question below is still open)

## Goal

The host builds from `~/nixos` and every capability it declares actually works: one
declarative source for system config, Hermes identity, and the agent's operating rules.

## Done when

- `sudo nixos-rebuild switch --flake ~/nixos#<host>` succeeds and the running system matches
  the built store path already produced by the tooling session.
- `/var/lib/hermes/.hermes/SOUL.md` matches `modules/config/hermes/SOUL.md` (diff clean).
- The tooling plan's verification matrix passes with **real calls**: TTS, memory write, browser,
  MCP. `computer_use` is **excluded** — upstream-blocked, not fixable here (see Decisions,
  2026-10-22).

## Status

active — the switch **has now run**: `/run/current-system` was activated 2026-10-22 12:11 and
the live system matches source. Verified 2026-10-22: `/var/lib/hermes/.hermes/SOUL.md` is
byte-identical to `modules/config/hermes/SOUL.md` (2898 B each, `diff` clean); `hermes config
check` reports live **v50** (the offered v51 is an upstream schema bump, not a repo change);
`/var/lib/hermes/.hermes` is mode `2750`, not the upstream `2770`; `tailscaled` is active and
enabled; the running `firewall-start` carries both 27015 and 27016.

The phone-access workstream is **committed and activated**. Commits `208fcba` (module + host
import + runbook) and `496867d` (`flake.lock`), behind the 13:38 switch. Verified 2026-10-22
15:00 against the live system: `tailscaled`, `syncthing`, `sshd` all **active and enabled**;
`tailscale ip -4` → `<tailnet-ip>`; `/etc/ssh/sshd_config` shows `no` on both
`PasswordAuthentication` and `KbdInteractiveAuthentication`; `~chloe/.ssh/authorized_keys` holds
exactly one ed25519 line (`@ Termux`, mode 600); `receive.denyCurrentBranch = updateInstead` in
**13/13** repos under `~/projects`. `nix eval` on the flake (with a writable `XDG_CACHE_HOME`)
returns `PasswordAuthentication=false`, `KbdInteractiveAuthentication=false`, `UsePAM=true`,
`trustedInterfaces=[tailscale0, lo]`, syncthing `user=chloe group=users openDefaultPorts=false`,
and its `ExecStart` uses `--data=/home/chloe/.config/syncthing`, so `dataDir` does **not** scatter
cert/db files into the home root.

**Syncthing pairing: config complete 2026-10-29, waiting on one switch.** `modules/remote-access.nix`
declares the device (`settings.devices.phone.id = QTQIILO-RJK6M6J…`,
name `chloe-phone_redmi-note-15-pro`, ID checksum-validated by `/rest/svc/deviceid`) and shares
`Mind` + `wiki` with it, both with ignore patterns and 30-day staggered versioning. Verified at the
*artifact* level, not just by eval: the rendered `syncthing-init` script
(`/nix/store/3wqi41by…-merge-syncthing-config`) POSTs the device and each folder and DELETEs stale
entries, and both folder payloads carry
`"devices":[{"deviceId":"QTQIILO-RJK6M6J…"}]`.

Live state is unchanged until the switch: at 23:26 the REST API still showed `config/folders` →
`[]`, `config/devices` → one entry (`chloe-laptop`), `system/connections` → `{}`. The phone node
`redmi-note-15-pro-5g` answers `tailscale ping` (77 ms) but **refuses 22000**, i.e. Syncthing-Fork
is installed but its sync service is not started — that is the remaining phone-side step, and it
gates any connection attempt from the host.

**Review + commit pass 2026-10-30 00:41 — tree clean, nothing switched.** All 15 changed/untracked
paths were read and committed as six workstream commits plus two docs commits (`5ead763` hermes
native again, `2a246da` XFCE/X11 output + one-GPU nvidia, `4d74a72` desktop launcher, `7090181`
declarative Syncthing + dashboard unit, `8e8d3a0` hermes config, `8aa6ddf` Android SDK + libresprite,
`9131ee3` rollback record, `4eb500f` `AGENTS.md` + `ARCHITECTURE.md`). The tree now has the hot-tier
context files that were missing: `AGENTS.md` (verified commands, permission boundary) and
`ARCHITECTURE.md` (outputs by `desktop`, module map, invariants with a check each, and what is not
verified yet).

All four outputs evaluate: each returns a `nixos-system-chloe-laptop-26.05.20260719.fd14620.drv`
path, and **no drvPath value is recorded here on purpose** — `modules/revision.nix` folds the flake
revision into the system, so the path changes on every commit, including the commit that would carry
the number. Re-derive it, do not read it:
`for o in chloe-laptop chloe-laptop-niri chloe-laptop-plasma chloe-laptop-xfce; do nix eval --raw
".#nixosConfigurations.$o.config.system.build.toplevel.drvPath"; done`.
`/run/current-system` is still `6c9apnv4…` (activated 2026-10-29 21:32), so none of this is live.

**Review + commit pass 2026-11-09 — tree clean, nothing switched.** Seventeen changed/untracked
paths were read, checked against the built store rather than against their own comments, and
committed as ten workstream commits: the `pi` harness (upstream flake input pinned to a commit,
plus a `bwrap` sandbox), the headless `lmstudio` user unit on `:1234` and the `lms` binary fix in
`modules/llm.nix`, `gaming-mode`, the VS Code markdown preview, `uv`, the stylix Obsidian `force`,
`at-spi2-core` on the XFCE output, the scoped Jellyfin firewall rule and KDE Connect. The gnome
toplevel was **built**, not only evaluated (34 derivations, all realised), so the switch is a copy
plus activation. Live state is unchanged until she runs it.

## Next action

**Next action (Chloe, one command):** `sudo nixos-rebuild switch --flake ~/nixos#chloe-laptop` —
the 2026-11-09 set (pi, the lmstudio endpoint, gaming-mode, the markdown preview, uv, kdeconnect,
at-spi, the scoped Jellyfin rule) on top of everything below. The gnome toplevel is already built
from this tree, so expect a copy and activation rather than the 252-derivation build the
2026-10-30 paragraph predicts. After the switch, once:

```
systemctl --user daemon-reload && systemctl --user restart lmstudio
```

home-manager relinks that unit file about a second *after* systemd restarts it, so the first start
runs the previous definition.

**Next action as of 2026-10-30:** `sudo nixos-rebuild switch --flake ~/nixos#chloe-laptop`.
Everything is committed (last content commit `4eb500f`, this ledger on top of it), so this one
switch activates the whole set: native gateway
again, the XFCE output, declarative Syncthing, `hermes-dashboard.service`, the dayboard/a2a/kanban
config, and the Android toolchain. It is a real build, not an instant one: `nix build --dry-run` on
the gnome output reports **252 derivations to build, 84 paths to fetch (595.8 MiB)**.

Then, in this order:

1. **Syncthing pair (needs the phone).** Start Syncthing-Fork — its toggle, and port 22000 must come
   up — accept the incoming request from `chloe-laptop`, accept `Mind` and `wiki` into real
   folders, point Obsidian at `Mind`. From the host:
   `curl -s -H "X-API-Key: $(xmllint --xpath 'string(configuration/gui/apikey)'
   ~/.config/syncthing/config.xml)" 127.0.0.1:8384/rest/config/folders | jq -r '.[].id'`
   must print `mind` and `wiki`, and `/rest/system/connections` must show the phone once it is on.
2. **XFCE login, once.** Log into `chloe-laptop-xfce` and check the session holds: the first X11
   attempt on this host died 8 s past ly's greeter (broken PRIME `amdgpuBusId`, fixed in
   `hardware/nvidia.nix`, never tested live). `hermes computer-use doctor` is the tool that reports
   whether the driver sees the session.
3. **Dashboard.** `systemctl status hermes-dashboard` → active, and from the phone
   `http://<tailnet-ip>:9119` must answer with a login prompt, not connection-refused. Untested; exit
   78 parks the unit if another dashboard already owns the host.
4. **Dayboard stays inactive** until `DAYBOARD_AGENT_TOKEN` exists in
   `/var/lib/hermes/.hermes/.env` (agenix): `hermes plugins list` will otherwise show it enabled with
   its tools absent.

**Stopping point:** a file edited in Obsidian on the phone appears in `~/Mind` on the host, and a
phone push shows up in `git -C ~/projects/ai-research-lab log -1` on the host. Nothing else in
`~/nixos` is waiting on this workstream.

## Open questions

- ~~Which host config is active: `chloe-laptop`, `-niri`, or `-plasma`?~~ Answered 2026-10-22 —
  `chloe-laptop` (`/run/current-system` →
  `nixos-system-chloe-laptop-26.05.20260719.fd14620`).
- ~~Kanban trial~~ **Closed 2026-10-30.** The trial was stopped and then fully reversed the same
  evening (Chloe, recorded in `modules/config/hermes/config.yaml`): kanban is re-enabled with
  **upstream defaults** — `dispatch_in_gateway`, `auto_decompose`, `review_dispatch`,
  `notify_in_gateway`, `auto_subscribe_on_create` all true — and the `kanban` toolset is in
  `platform_toolsets.cli`. The only control is therefore still the 2026-10-22 rule: the board holds
  approved work only, because a card is a start signal.
- **The tailnet address is now in this repo, against the 2026-10-22 identifier rule.** `7090181`
  puts the literal tailnet IP in `modules/remote-access.nix` twice — once in a comment, once as the
  dashboard unit's `--host`. Decision owed by Chloe before the branch is pushed (`desktop/gnome-daily`
  is still unpushed: `origin/main` is at `d037b73`). Options: (a) keep it and record why this one
  address is execution-critical, (b) derive it at start — `Environment`/`ExecStart` through a shell
  that runs `tailscale ip -4`, so no literal is committed, (c) bind the dashboard to all interfaces
  and rely on `trustedInterfaces = [ "tailscale0" ]`, which removes the literal but listens on wlo1
  too (the firewall still drops it). Recommendation: (b).
- **Dayboard has no token.** `plugins.enabled: [dayboard]` is committed, but the plugin declares
  `requires_env: DAYBOARD_AGENT_TOKEN` and no such key exists in `/var/lib/hermes/.hermes/.env`, so
  its tools will be absent after the switch. Either the token goes into the agenix-managed env or the
  plugin comes back out of `enabled`.
- image_gen / video_gen providers: still off, still a purchase decision.
- Memory caps: committed at 3000/1600 without the two-week measurement the tooling plan
  suggested. Watch for rejection traffic before raising further.

## Decisions

- 2026-10-20 — ledger is state, plan is intent, queue is a board, index is links — four drift
  risks collapse into one authoritative status location.
- 2026-10-20 — kanban is a *candidate*, not adopted; nothing about it goes into SOUL, so
  dropping it costs no rebuild.
- 2026-10-20 — dispatch thresholds live in `profile-task-dispatch`, not SOUL — policy tuning
  stays off the rebuild path.
- 2026-10-20 — lane B is the default: authoring work goes to the owning profile even when
  small; only reasoning and verification stay inline (Chloe, explicit).
- 2026-10-20 — ledger scope: multi-session projects only (Chloe, explicit). One-evening jams
  are out.
- 2026-10-20 — corrections found *during verification* are applied by the verifier and logged,
  not re-dispatched: a two-integer fix does not justify a second 100 s worker boot.
- 2026-10-20 — TTS is local Piper, not edge: Microsoft's endpoint 403s the handshake
  (recorded in the committed tooling plan and config comment).
- 2026-10-20 — project goals recorded from Chloe, replacing both README inferences:
  UnityXR = interactive virtual museum exhibit for Quest 3; chloes-2d-library = modular Godot
  code library extracted from existing projects and reused on new games.
- 2026-10-22 — **kanban trial starts now, one week** (Chloe, explicit: "Yes — trial it for one
  week"). Semantics that govern the trial, discovered the hard way the same hour: `kanban.
  dispatch_in_gateway: true` (60 s tick) and `auto_decompose: true` (3/tick) are **Hermes defaults,
  not our config**, so the gateway spawns profile workers for `ready` cards on its own and splits
  `triage` cards into `ready` subtasks. A card on the board is therefore a *start signal*, not a
  note. Trial rule, as Chloe decided after the incident: **dispatch stays ON**, and only work she
  has approved goes on the board, one card at a time — nothing idle, nothing for display. Review
  date 2026-10-29 (one-shot cron job `41232264b587`).
- 2026-10-22 — **`computer_use` is closed as upstream-blocked, not fixed** (Chloe, explicit).
  Re-verified from this session and from the capture session `20261021_083351_5ae925`: every
  capture mode fails or returns a 0×0 empty AX tree, and there is no local fix available — the
  blocker is in the upstream driver, so this is parked rather than worked around. Nothing in
  `modules/hermes.nix` should chase it again until upstream moves. Remove it from the
  "Done when" matrix rather than leaving it as permanently-red.
- 2026-10-22 — **network identifiers never enter this repo** (Chloe, explicit: "scrub
  identifiers"). `origin` is `git@github.com:dollythecamus/chloe_NixOS.git` and it is **public**,
  so any doc recording a WAN address, LAN address, gateway MAC or the host's tailnet address
  carries `<wan-ipv4>`, `<lan-ipv4>`, `<gateway-mac>`, `<isp-reverse-dns>`, `<tailnet-ip>` plus a
  note naming the command that re-derives each one (`curl -s https://api.ipify.org`,
  `ip -4 -o addr show wlo1`, `ip neigh show 192.168.0.1`, `tailscale ip -4`). Checked before committing: `git grep` over `HEAD` had none of
  those values, so the first commit of such a doc is the exposure.

- 2026-10-29 — **the phone's Syncthing device ID is published in this public repo** (Chloe's call,
  after being shown the alternatives). Reasoning on record: the ID is the SHA-256 of the device
  certificate — a public-key fingerprint, not a credential — so holding it grants no access (auth
  compares cert hashes; the private key never leaves the phone). It does leak a stable identity link
  (GitHub account ↔ this phone's sync endpoint) and the device's announced relay address.
  Rejected alternatives: **agenix** cannot supply it (agenix is for runtime files —
  `config.age.secrets.X.path`, as `hermes-env` uses it — while this option needs a string at *eval*
  time, which lands in the world-readable `/nix/store` anyway, so it would hide nothing);
  **local-file + `--impure`** fails measured: `nix eval --pure-eval` on an absolute path errors,
  `pathExists` returns `false`, so a rebuild without the flag would silently declare no device and
  `overrideDevices = true` would then un-pair the phone. Optional follow-up if the residual leak
  ever matters: `settings.options.announceLANAddresses = false`.

- 2026-10-30 — **review pass commits in workstreams, ledger last** (Chloe asked for one review +
  commit of the whole tree). Six content commits and two docs commits, each of which evaluates on
  its own; the ledger commit names only shas that already exist. Pitfall hit once and repaired with
  `git reset --soft`: three paths were already in the index from an earlier session, so
  `git add modules/hermes.nix` + commit swept them into the wrong commit. Read
  `git status --porcelain` before staging, and stage explicit paths.
- 2026-10-30 — **the hermes-agent package rebuild is not a regression.** The tree's package drv
  (`wgyysls6…`) differs from the live one's deriver (`f8g0wh91…`), and **`HEAD` evaluates to the same
  new drv**, so the divergence predates this pass (the live generation was built from an earlier
  tree). The new sealed env `g813h147…-hermes-agent-env` is already in the store and contains
  `numpy 2.4.3`, `faster-whisper 1.2.1`, `ctranslate2`, `av` — the extras `extraPythonPackages`
  declares, so STT and holographic structural recall survive the switch.
- 2026-10-30 — **the 2026-10-22 "computer_use is closed, do not chase it again" decision is
  superseded in part**: an X11 output (`chloe-laptop-xfce`) now exists because the driver's capture
  and input path needs an X server here. The tool itself is still **unverified** — no XFCE session
  has ever held — so it stays out of the "Done when" matrix until one does.
- 2026-10-30 — **XFCE is a permanent output, not a branch experiment** (Chloe, 2026-10-29: accepted
  as part of the switch). It stays one of the four `desktop` values, gated in the five modules that
  branch on it, and `AGENTS.md` names that gate as load-bearing.
- 2026-11-09 — **Jellyfin's 8096 is scoped to the house LAN, not opened globally** (Chloe: "scope
  for security"). `allowedTCPPorts` would serve the library on every interface the laptop joins;
  the rule is instead `-i wlo1 -s 192.168.0.0/24` for tcp/8096. The tailnet is unaffected —
  `remote-access.nix` trusts `tailscale0`. Accepted failure direction: a router subnet change or a
  wired connection stops the stick reaching Jellyfin until the prefix/interface is updated, rather
  than the port silently being open somewhere unexpected.
- 2026-11-09 — **`.md` opens as a rendered preview in VS Code by default** (Chloe: kept, explicitly
  wanted). Editing therefore needs "Reopen Editor With…" or Ctrl+Shift+V. The line lives in
  `home/vscode.nix` and deleting it reverts to text-first.

## Evidence

- 2026-11-09 — **review pass.** All four outputs evaluate (`nix eval --raw
  .#nixosConfigurations.<out>.config.system.build.toplevel.drvPath`, `XDG_CACHE_HOME` set),
  re-run after the network edit; the gnome toplevel was then **built**: `nix build --dry-run`
  reported 34 derivations to build and 4 paths to fetch, and `nix build` realised it.
  Option-level checks: `services.gnome.at-spi2-core.enable` is `true` on gnome *and* xfce, and
  `NO_AT_BRIDGE`/`GTK_A11Y` are gone from the xfce `environment.sessionVariables`; the merged VS
  Code `userSettings` carries both Stylix's `markdown.preview.fontFamily` and this repo's
  `markdown.styles`, so no key is defined twice; `home.file."Mind/.obsidian/appearance.json"` is
  `{force=true, source=<stylix's appearance.json>}` — the declaration to merge into exists, so it
  is not an orphan file entry; `firewall.allowedTCPPorts` is back to `[22, 27015, 27036, 27037]`.
- 2026-11-09 — **the backend check that changed the Jellyfin fix.** `networking.nftables.enable` is
  `false` on this host, and `firewall.extraInputRules` is declared by the *nftables* module only:
  setting it evaluates clean and is silently ignored, so the first version of the scoped rule
  would have left 8096 shut with no error anywhere. The committed rule uses `extraCommands`, and
  the built `firewall-start` script shows it at line 138 —
  `iptables -w -A nixos-fw -i wlo1 -s 192.168.0.0/24 -p tcp --dport 8096 -j nixos-fw-accept` —
  two lines before the `nixos-fw-log-refuse` at 142.
- 2026-11-09 — the `pi` claim checked at the binary, not the comment: `pi --version` → `1.5.0`
  (`/etc/profiles/per-user/chloe/bin/pi`), and `~/.pi/agent` holds 83 sessions, so the pinned commit
  builds and runs. The `lms` split likewise holds in the live profile: `lms` and `llmster` resolve
  into `lmstudio-server-0.0.13-1`, `lmstudio` into `lmstudio-0.4.19-2`, one `lms` and no collision.
- 2026-11-09 — `fish -n home/fish/gaming-mode.fish` passes; `git diff 4405adc..HEAD --check` prints
  nothing.

- 2026-10-30 00:41 — **review pass.** Evaluation, all four outputs (with
  `XDG_CACHE_HOME=$HOME/.hermes/cache/scratch/nixcache`): `nix eval --raw
  .#nixosConfigurations.<out>.config.system.build.toplevel.drvPath` → four distinct
  `nixos-system-chloe-laptop-*.drv` paths, run twice (dirty tree and again at HEAD); the gnome one
  moved `q40dv6kr…` → `zz57qq18…` between runs because `modules/revision.nix` embeds the revision;
  no assertions fire, the only warnings are
  `hermes-dashboard.service is ordered after network-online.target but doesn't depend on it` and the
  pre-existing `appimageTools.extractType2` deprecation.
- 2026-10-30 — `nix build --dry-run …toplevel` (gnome): `252 derivations will be built`, `84 paths
  will be fetched (595.8 MiB download, 938.7 MiB unpacked)`.
- 2026-10-30 — live state before the pass: `/run/current-system` →
  `nixos-system-chloe-laptop-26.05.20260719.fd14620`, `stat` 2026-10-29 21:32, `nix-store -q
  --deriver` → `6c9apnv4…`; `systemctl status hermes-dashboard` → "Unit … could not be found".
- 2026-10-30 — container-reversal values on the gnome output: `container.enable=false`,
  `workingDirectory=/home/chloe`, `users.users.chloe.linger=true`, `system.activationScripts` =
  `[agenix…, hermes-agent-setup, hermes-home-bridge, hermes-home-mode, …]` (no
  `hermes-container-cleanup`, no `hermes-container-exec-user`), `preStart` = the linger/user-bus wait.
- 2026-10-30 — xfce output: `services.xserver.videoDrivers = ["nvidia"]`,
  `hardware.nvidia.prime.offload.enable=false`, `amdgpuBusId=""`,
  `powerManagement.finegrained=false`, `displayManager.xserverArgs` = `[…, "-nolisten tcp",
  "-terminate", "-ac"]`, and `environment.sessionVariables` has **no** `WAYLAND_DISPLAY` /
  `QT_QPA_PLATFORM` keys (mkForce null removes them; nothing renders the string "null").
- 2026-10-30 — one-GPU claim re-measured without `lspci` (not installed):
  `for d in /sys/bus/pci/devices/*; do case "$(cat $d/class)" in 0x03*) echo $d;; esac; done` → one
  line `0000:01:00.0` `0x10de:0x25ec` driver `nvidia`; `ls /dev/dri` → `card1 renderD128`.
- 2026-10-30 — Syncthing payloads re-derived rather than quoted: `syncthing-init` ExecStart →
  `/nix/store/5xbv5g3v…-merge-syncthing-config`, whose script POSTs `…-devs-QTQIILO-…json` to
  `/rest/config/devices`, POSTs `dirs-mind-…`/`dirs-wiki-…` to `/rest/config/folders`, sets
  `rest/db/ignores?folder={mind,wiki}`, DELETEs stale ids and POSTs `rest/system/restart`. Both
  folder payloads carry `"devices":[{"deviceId":"QTQIILO-…"}]`, `versioning.type=staggered`.
- 2026-10-30 — dashboard unit: evaluated ExecStart =
  `/nix/store/…-hermes-agent-0.0.0/bin/hermes dashboard --host <tailnet-ip> --port 9119 --no-open
  --skip-build`; `--host/--port/--skip-build/--no-open` all exist in `hermes dashboard --help`;
  `/var/lib/hermes/.hermes/dashboard-auth.env` exists (`-rw------- chloe hermes`, 193 B);
  `tailscale ip -4` → the same address the unit uses; `getent group hermes` → `993:chloe`;
  `networking.firewall.trustedInterfaces = [ "tailscale0" ]`.
- 2026-10-30 — dayboard: `$HERMES_HOME/plugins/dayboard` exists (v1.0.0, `kind: tools`,
  `requires_env: [DAYBOARD_AGENT_TOKEN]`); `cut -d= -f1 $HERMES_HOME/.env` → `OPENCODE_GO_API_KEY,
  DISCORD_BOT_TOKEN, DISCORD_ALLOWED_USERS, DISCORD_HOME_CHANNEL, WIKI_PATH` — no dayboard token.
  `hermes plugins show dayboard` → "Status: not enabled" (the live config predates the commit).
  The config keys themselves are real: `plugins.enabled` is read in `hermes_cli/plugins_state.py`
  (`_enabled_from_config`) and `plugins.entries.<id>.allow_tool_override` in `tools/registry.py`
  (the override-denial message names it verbatim).
- 2026-10-30 — `git diff HEAD --check` printed nothing over the whole tree before the first commit;
  `git log --format='%an <%ae>'` shows one human author (Chloe) plus `Hermes <…>`, so the repo is
  single-owner and the ledger stays tracked.
- `git -C ~/nixos log --oneline -3` (2026-10-22 checkpoint) — `4c2334a docs: record repair build
  result`, `b39c791 hermes: local Piper TTS, computer_use gateway env, toolset gating, memory caps`,
  `94c8a9d networked`.
- Build result (from the committed plan): exit 0,
  `/nix/store/90lzjkk5slkgr5rj1sk5mfg2wd313a09-nixos-system-chloe-laptop-26.05.20260719.fd14620`.
- `diff -q /var/lib/hermes/.hermes/SOUL.md modules/config/hermes/SOUL.md` — DIFFERS at the
  2026-10-20 checkpoint (live 1832 B vs repo 2898 B). **Superseded 2026-10-22:** identical,
  2898 B each, `diff` clean.
- `hermes config check` — live v41 at that checkpoint. **Superseded 2026-10-22:** live v50
  (v51 offered is an upstream schema bump).
- 2026-10-22 — kanban seeding incident, contained with no damage. 7 cards created for the trial
  queue (6 via `--triage`); within ~2 minutes the gateway dispatcher had auto-decomposed 3 of them
  into 6 subtasks and had 3 workers running (`code` on the choice.tscn probe, `nixos` on SSH module
  wiring + a switch runbook), one subtask reaching `done`. Halted by `reclaim` → kill of
  `hermes_cli.kanban_worker_client` → `archive` of all 13 ids; board back to 0 in every column.
  Post-incident check of `~/nixos`, `chloes-2d-library` and `UnityXR_3DMuseu`: no new commits, no
  new files, working trees exactly as before (nixos `50f4245` + the same 5 pending paths; 2d-library
  clean at `823124d`; UnityXR `251d0f9` + the same 3 paths).
- 2026-10-22 12:11 — `/run/current-system` = `nixos-system-chloe-laptop-26.05.20260719.fd14620`,
  activated 12:11; `stat -c %a /var/lib/hermes/.hermes` → `2750`; `systemctl is-active
  tailscaled` → active, enabled; live `firewall-start` (`/nix/store/6wnqczzg…`) contains
  `dport 27015` and `dport 27016`; `grep -iE '^(PasswordAuthentication|KbdInteractive)'
  /etc/ssh/sshd_config` → both `yes`. **Superseded 15:00** — same system path, link reactivated
  13:38; sshd_config now `KbdInteractiveAuthentication no` / `PasswordAuthentication no`;
  `tailscale ip -4` → `<tailnet-ip>`; `syncthing` active + enabled.
- 2026-10-22 15:00 — pre-commit verification of the dirty tree: `nix eval` on
  `.#nixosConfigurations.chloe-laptop.config.{services.openssh.settings,services.syncthing,networking.firewall.trustedInterfaces}`
  (needs `XDG_CACHE_HOME` pointed at a writable dir — the default fetcher cache under
  `/var/lib/hermes/.cache/nix` is not writable from this shell) returns the values quoted in
  Status; `systemctl show syncthing -p ExecStart` → `--data=/home/chloe/.config/syncthing`;
  `awk '{print $1, $3}' ~chloe/.ssh/authorized_keys` → one `ssh-ed25519 … @ Termux` line, mode
  600; `receive.denyCurrentBranch` loop over `~/projects/*/` → 13/13 `updateInstead`.
- 2026-10-22 15:00 — **the runbook contradicted the module before this pass**: §1 told the reader
  to run `tailscale up` and §2 claimed `authorized_keys` was empty with `PasswordAuthentication`
  commented out, while the key was in place, the node had a 100.x address and both sshd options
  were already `false` in the module and `no` live. Corrected in `208fcba`; the `100.x.y.z`
  placeholders in the Termux block became `<tailscale-ip>` with the command that prints it.
- 2026-10-29 23:55 — rendered-payload check of the declarative Syncthing config (stronger than
  evaluation): built `/nix/store/3wqi41by…-merge-syncthing-config` from the drv inside the toplevel
  and read the JSON it will POST — `dirs-mind-conf-pre-secrets.json` and `dirs-wiki-…` both carry
  `"devices":[{"deviceId":"QTQIILO-…"}]`, the device object is
  `{"autoAcceptFolders":false,"deviceID":"QTQIILO-…","id":…,"name":"chloe-phone_redmi-note-15-pro"}`,
  ignores POST to `rest/db/ignores?folder={mind,wiki}`, and stale entries are DELETEd after the
  POSTs. `nixos-rebuild dry-build` evaluates clean; toplevel drv `cz65891x…` → `q40dv6kr…`.
  Device ID validity proven by `GET /rest/svc/deviceid?id=…` returning the ID with no error field.
- 2026-10-29 23:40 — **nixpkgs bug hit in this pin**: the attrset form of a folder device,
  `devices = [ { name = "phone"; } ];`, makes whole-system evaluation die with
  `error: expected a string but found null: null` at `syncthing.nix:216` — the folder-device
  submodule always materialises `encryptionPasswordFile = null`, and the init generator hashes it
  unconditionally (`hashString "sha256" device.encryptionPasswordFile`). Use the string form,
  `devices = [ "phone" ];`, which takes the `cfg.settings.devices.<name>.id` branch instead. A
  recorded note in the module says so.
- 2026-10-29 23:30 — Syncthing vault work, second pass. Live unit `active`+`enabled`, `v2.1.1`,
  `configDir=/home/chloe/.config/syncthing`, GUI `127.0.0.1:8384`. Both paths are real Obsidian
  vaults (`~/Mind/.obsidian`, 46 files, 2.1 MB; `~/wiki/.obsidian`, 344 files, 2.7 MB, and
  `~/wiki` is a git repo — `.git` 2.4 MB, 5 files dirty at HEAD `337beba`).
  `modules/remote-access.nix` now declares `settings.folders.mind`/`.wiki`; eval returns both with
  `ignorePatterns` and `versioning.type=staggered`, `overrideFolders=true`,
  `overrideDevices=true`; toplevel drv `qczx5arq…` → `cz65891x…` (the pre-edit drv already
  differed from the live deriver `6c9apnv4…`, i.e. the tree carries unbuilt work). Not switched.
  Pinned module read at `/nix/store/m0chqc0…-source/nixos/modules/services/networking/syncthing.nix`:
  the init script POSTs each declared entry and DELETEs undeclared ones when override is true —
  a GUI-added device would be removed at the next activation, which is why the phone gets declared
  rather than clicked.
- `hermes doctor` / `config check` — no `stt` unknown-toolset warning surfaced; `stt` is kept
  in all three platform toolset lists.
- `hermes profile list` — 4 profiles, all gateways running.
- `hermes kanban stats` — every column 0; board never used.
- Dispatch re-check: `git status --porcelain -uall` in both project repos — 13/5 and 36/9
  (modified/untracked), HEADs unchanged, reflog top unchanged (no commit by the worker).

## Uncommitted at last checkpoint

This workstream — committed in the same commit as this ledger:
- `modules/config/hermes/SOUL.md` — new `# Continuity and routing` section (+9 lines)
- `docs/hermes-operations-plan-2026-10-20.md`
- `docs/PROJECT_LEDGER.md` (this file)

Not this workstream, now committed: `docs/stationeers-hosting-plan.md` went in as `cf5eab5`, with
its measured identifiers replaced by placeholders — the GitHub remote is public and its history
carried none of those values.

Already committed by the concurrent session: `modules/config/hermes/config.yaml`,
`modules/hermes.nix`, `docs/hermes-{behavior,tooling-repair}-plan-2026-10-20.md`.

Outside this repo, committed in their own repos: `UnityXR_3DMuseu/docs/PROJECT_LEDGER.md`,
`chloes-2d-library/docs/PROJECT_LEDGER.md`.

## Uncommitted at 2026-11-09

None. `git status --porcelain -uall` printed nothing before this ledger commit: the seventeen
reviewed paths are ten workstream commits on `4405adc`, and this file is the last commit on top.
Branch `desktop/gnome-daily` is still **unpushed** (`origin/main` unchanged).

## Uncommitted at 2026-10-30 00:41

`git status --porcelain -uall` in `~/nixos` listed only `M docs/PROJECT_LEDGER.md` before this
commit — everything else from the review pass is committed, this ledger is its last commit. The
eight commits sit on `92b781f` (see Status). Branch `desktop/gnome-daily` is **unpushed**:
`origin/main` is at `d037b73`.

## Uncommitted at 2026-10-29 23:30

`git status --porcelain -uall` in `~/nixos`: **13 paths, only `modules/remote-access.nix` from this
pass** (and that file is shared with the container workstream): modified `flake.nix`,
`hardware/nvidia.nix`, `home/chloe.nix`, `home/home-programs.nix`, `host_chloe-laptop.nix`,
`modules/config/hermes/config.yaml`, `modules/cua-driver.nix`, `modules/hermes.nix`,
`modules/remote-access.nix`; staged `home/desktop-gnome.nix`, `home/hermes-desktop-launcher.nix`,
`modules/desktop/xfce.nix`; untracked `docs/hermes-container-rollback-2026-10-27.md`. HEAD
`92b781f`. Nothing committed from this pass — the container workstream owns that tree.

## Uncommitted at 2026-10-22 15:02

`git status --porcelain -uall` in `~/nixos`: **clean** — 0 staged, 0 modified, 0 untracked.
HEAD `496867d flake: hermes-agent 53df274 -> 69c7d67`, with this ledger commit on top.

Superseded snapshot (12:40, HEAD `cc59d60`): 6 paths — 2 staged (`docs/phone-access-runbook.md`,
`modules/remote-access.nix`), 3 modified (`flake.lock`, `host_chloe-laptop.nix`,
`modules/hermes.nix`), 1 untracked (`docs/stationeers-hosting-plan.md`). `modules/hermes.nix` was
committed by the concurrent session; the rest are in `208fcba` / `cf5eab5` / `496867d`.

## Handoff

**Changed (2026-10-30 review pass):** the whole pending tree reviewed and committed in eight
commits — native gateway restored, XFCE/X11 output added, one-GPU nvidia (no PRIME offload),
desktop launcher override, declarative Syncthing + `hermes-dashboard` unit, dayboard/a2a/kanban
config, Android SDK + libresprite, container-rollback record, and the new `AGENTS.md` +
`ARCHITECTURE.md`. Nothing switched.

**Verified:** all four outputs evaluate; the dry-run cost is 252 derivations / 595.8 MiB fetched;
the container hooks are absent from the evaluated config; the Syncthing init payloads carry the
phone and both folders; the dashboard unit's ExecStart, auth-env file, tailnet address, group and
firewall trust all check out; the new sealed hermes env carries numpy/faster-whisper.

**NOT verified:** no XFCE session has logged in; `hermes-dashboard.service` has never started;
Syncthing still has zero folders live; dayboard has no token; container-mode Phase 4 cleanup is
still Chloe's sudo. The one decision owed before the switch is the tailnet-IP question in *Open
questions*.

**Changed (2026-10-20, kept for history):** SOUL source gains a six-rule continuity/routing section;
`project-ledger` skill + template created (runtime, profile `default` only); `profile-task-dispatch`
gains dispatch shapes, prompt budget and the dispatch-log contract; operations plan written;
ledgers created for this repo and the two project repos (the latter by a `code` dispatch, goals
then corrected from Chloe's wording); all committed.

**Landed alongside (other session, already committed and built):** local Piper TTS, CUA driver
+ Wayland/X11 env on `hermes-agent.service`, toolset gating (cron without `computer_use`),
memory caps 3000/1600, config v50.

**Verified:** SOUL differs from live only by the new section (repo ahead, as expected); both
skills load through `skill_view`; both project ledgers re-checked against `git status
--porcelain -uall` and corrected (each had undercounted its own untracked file); no worker
committed anything; the tooling session's build returned exit 0.

**NOT verified (2026-10-20 text, kept for history):** nothing had been through a switch at that
point; the CUA environment was untested, the kanban trial had not run, the `code` profile had no
`project-ledger` skill installed.

**Superseded 2026-10-22:** the switch has run and live matches source (SOUL, config v50,
`.hermes` mode). Still open: the phone-SSH hardening activation, the kanban go/no-go, and
`computer_use` (parked, upstream-blocked).

## Dispatches

- 2026-10-20 22:34 · dispatch → learn · smoke test, one-word reply · session
  20261020_223403_dfa500 · verified (returned `OK`; 23.2 s wall)
- 2026-10-20 23:18 · dispatch → code · create ledgers for UnityXR + 2d-library · session
  20261020_231820_12b208 · verified with correction (100 s wall; both files written, counts
  fixed 4→5 and 8→9 untracked; no commits)

## Requirements log

- 2026-10-20 (session 20261020_222629_e4ff94) — "task-doing profile should take authoring work
  and keep projects logged/current" → ops plan lanes + SOUL routing rules + `project-ledger`
  skill.
- 2026-10-20 (session 20261020_222629_e4ff94) — "kanban: tell me more before committing" →
  briefing + trial + decision gate in the ops plan; not adopted.
- 2026-10-20 (session 20261020_222629_e4ff94) — "changes must go through the nixos
  configuration" → all identity/config edits made in `modules/config/hermes/`, nothing written
  to the live copies.
- 2026-10-20 (session 20261020_222629_e4ff94) — "sub-5-minute tasks are fine to route to the
  task-doing profile" → lane B encoded as the default for authoring work.
- 2026-10-20 (session 20261020_222629_e4ff94) — "ledger only for multi-session projects" →
  scope line in the `project-ledger` skill; one-evening jams excluded.
- 2026-10-22 (session local-1d5eb9d9…) — "verify dirty changes in this repo to commit" → the
  three phone-access paths verified against the live system, three stale runbook claims and the
  stale ledger status corrected, committed as `208fcba`; the stationeers doc that
  `modules/network.nix` cites committed as `cf5eab5` with identifiers scrubbed; `flake.lock`
  committed separately as `496867d` (Chloe's choice of order).
- 2026-10-29 (session local-b6dacb5c…) — "set up obsidian vaults between pc and phone with
  syncthing in the nixos configuration" → folders made declarative in
  `modules/remote-access.nix` (mind + wiki, ignore patterns, staggered versioning). Chloe supplied
  the phone's device ID herself and put it in the module as a plain string (see Decisions); share
  links added by the agent. Config complete, switch not yet run.
- 2026-10-20 (session 20261020_222629_e4ff94) — goals stated for UnityXR and chloes-2d-library
  → written into both repo ledgers, replacing the README inferences.
- 2026-10-30 00:41 (session local-d0bb155c…) — "go in ~/nixos and review diff to commit changes
  (all ok, but also first review and notify if there's any big problem, anything small is fine),
  also apply /docs-driven-dev-pipeline and /project-ledger to organize it and keep it consistent
  with our project directories' procedure" → every path read and reviewed against evaluation and
  live state; **no blocking problem found**; committed as six workstream commits + two docs
  commits; `AGENTS.md` + `ARCHITECTURE.md` written as the repo's hot tier (the pipeline's stage-0
  retrofit it lacked); this ledger rewritten as the close. Small findings reported to her rather
  than fixed unilaterally: the tailnet IP versus the identifier rule, the missing dayboard token,
  the `network-online.target` ordering warning, dead `sway-prototype` conditions.
- 2026-11-09 (session local-13fdd66d…) — "see git diff on /home/chloe/nixos with unstaged and
  uncommited changes, review changes with me and commit" → all 17 paths read, and every comment
  checked against the built store instead of taken at face value (`pi --version` 1.5.0 with 83
  sessions on disk, `lms`/`llmster` resolving into `lmstudio-server`, the merged VS Code settings,
  the obsidian file's `source`+`force`, `fish -n` on gaming-mode). One finding changed the code:
  the Jellyfin rule first used `firewall.extraInputRules`, which this host's iptables backend
  ignores silently — rewritten to `extraCommands` and verified in the built `firewall-start`. Three
  questions asked, answers given: scope 8096 for security, keep `.md`-as-preview (the caveat
  comment was the agent's, not hers), ten workstream commits. Committed as ten workstream commits
  plus this ledger; nothing switched.
- 2026-11-09 (session local-5efa0a6c…) — "hermes sessions hang when HOME is defined as not
  /home/chloe … i'm undecided what is better, help me decide" → measured instead of guessed: the
  only HOME-bound tool credentials are `gh` (`~/.config/gh/hosts.yml`, and its failure exits 0
  with a "please run gh auth login" banner) and `pi` (`~/.pi/agent/auth.json` = `{}`); `git`
  https works through `/etc/gitconfig`'s libsecret helper + the unit's `DBUS_SESSION_BUS_ADDRESS`,
  `ssh` works because OpenSSH expands `~` via passwd so it already reads
  `/home/chloe/.ssh/config`, and `opencode` reads its key from
  `{file:~/.hermes/.opencode-go-key}` inside HERMES_HOME — so `ssh`/`git` need no copy at all and
  `gh`'s token lives in the per-user keyring, which makes a copied `hosts.yml` isolation in name
  only. Decision (hers): `HOME=/home/chloe` (`lib.mkForce`, upstream defines it without
  `mkDefault`) with HERMES_HOME unchanged at `/var/lib/hermes/.hermes`; verified in
  `nixos-rebuild build` output and by `gh auth status` / `pi -p` under that HOME. Separate,
  unfixed finding: the system unit has restarted 147× because the desktop app's own gateway
  (PID 4071, `app-hermes-3932.scope`) owns the host lock — "Attach is impossible: PID 4071
  published no usable host record" — so cron/Discord are not running; which gateway should own
  the host was asked and not answered. Switch not yet run.
