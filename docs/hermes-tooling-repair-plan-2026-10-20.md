# Hermes tooling / configuration / memory repair plan

Written 2026-10-20. Scope: make every enabled capability actually work, remove config drift,
and put the memory system back under budget. Does **not** cover prompt or communication
changes — that is `hermes-behavior-plan-2026-10-20.md`.

Owner split: the agent edits repo files and runs builds; Chloe runs `sudo nixos-rebuild switch`
and any command that needs her password.

## Constraints that shape every step

- `~/nixos/modules/config/hermes/config.yaml` is **installed at activation**. Editing
  `~/.hermes/config.yaml` is a runtime edit that the next switch reverts. All config changes
  go in the repo file, then a rebuild.
- Same for `SOUL.md`: source is `~/nixos/modules/config/hermes/SOUL.md` (currently identical
  to the live copy — verified by diff).
- `pm install` is broken on the sealed layout (missing `uv.lock`). Python dependencies go in
  `extraPythonPackages` in `modules/hermes.nix`, using
  `config.services.hermes-agent.package.python.pkgs` (same pattern as numpy).
- The gateway is a **system** unit (`hermes-agent.service`, runs as `chloe`, uid 1000). Its
  PATH is a fixed store list that does **not** include `/run/current-system/sw/bin`, and its
  environment has no `WAYLAND_DISPLAY` / `DISPLAY` / `XDG_RUNTIME_DIR`. Both facts matter
  for computer_use.

## Current state (verified 2026-10-20)

| Item | State | Evidence |
|---|---|---|
| Config version | v41, shipped v50 | `hermes config check`; migration diff is 2 lines |
| Repo ↔ live drift | live has `gateway.multiplex_profiles: true`, repo does not | `diff` |
| TTS | **fails** | `No TTS provider available`; default provider is `edge`, SDK absent |
| edge-tts in pinned nixpkgs | **available, 7.2.8** | `nix eval …python3Packages.edge-tts.version` |
| computer_use | **not loaded** | driver 0.28.1 exists at `/run/current-system/sw/bin/cua-driver`; resolver only checks `HERMES_CUA_DRIVER_CMD` or pm |
| Service env | no CUA var, no Wayland vars | `systemctl show hermes-agent -p Environment` |
| Built-in memory | 2,176/2,200 (98%); USER 1,234/1,375 (90%) | `~/memories/*.md`; 8 rejected writes |
| Holographic memory | healthy: structural recall **on**, 23 facts | `fact_store stats`; 19/23 facts have no keywords |
| `stt` toolset | referenced but unknown to config | `hermes config migrate` warns `unknown toolset 'stt'` |
| Uncommitted work | UnityXR 16 entries, chloes-2d-library 37 | `git status` |

---

## Phase 0 — baseline and drift sync (20 min, no rebuild)

1. Commit the pending `~/nixos/docs/stationeers-hosting-plan.md` (currently untracked).
2. Copy the live-only key into the repo config so activation cannot drop it:

   ```yaml
   gateway:
     multiplex_profiles: true
   ```

3. Back up current state (rollback anchor):

   ```bash
   cp ~/.hermes/config.yaml ~/.hermes/config.yaml.bak-$(date -u +%Y%m%dT%H%M%SZ)
   cp ~/.hermes/memories/MEMORY.md ~/.hermes/memories/MEMORY.md.bak-$(date -u +%Y%m%d)
   cp ~/.hermes/memories/USER.md   ~/.hermes/memories/USER.md.bak-$(date -u +%Y%m%d)
   git -C ~/nixos rev-parse HEAD > /tmp/hermes-repair-base.rev
   ```

**Done when:** repo config diff against live shows only the `connections`/version migration
(later) and no other drift.

---

## Phase 1 — TTS (blocks terminal-vtuber)

**Outcome 2026-10-21: edge is dead, Piper is the working provider.** Two independent failures:
`edge-tts` in `extraPythonPackages` pulls `aiohttp`, which collides with the sealed venv and
aborts the Hermes wrapper build; running the CLI standalone gets past DNS only with the threaded
resolver and then Microsoft rejects the websocket with `403`. Do not retry edge without a new
upstream fix.

Working configuration:

1. `pkgs.piper-tts` in `environment.systemPackages`.
2. `en_US-amy-medium.onnx` + `.json` fetched by hash (`fetchurl`) and installed at
   `/etc/hermes/piper/` via `environment.etc`.
3. `tts.provider: piper-cli` with a command provider:

   ```yaml
   command: "/run/current-system/sw/bin/env -u PYTHONPATH /run/current-system/sw/bin/piper -m /etc/hermes/piper/en_US-amy-medium.onnx -i {input_path} -f {output_path}"
   format: wav
   ```

4. Build exit 0; the built unit carries the CUA environment and the voice symlinks resolve.
5. Post-switch verify: `hermes doctor --live`, then `text_to_speech` with one sentence; expect a
   `.wav` path that plays.

**Risk:** Piper is CPU-only and local, so it adds ~1–2 s per sentence; no network dependency.
`terminal-vtuber` keeps its own espeak-ng voice path — this does not change it.

---

## Phase 2 — computer_use (staged; do not promise success in one pass)

The binary is packaged and present; the failure is purely that the gateway process cannot see
it, and probably cannot see the compositor either. Fix in two stages.

### Stage A — driver path (one rebuild)

`~/nixos/modules/hermes.nix`, top level:

```nix
systemd.services.hermes-agent.environment = {
  HERMES_CUA_DRIVER_CMD = "/run/current-system/sw/bin/cua-driver";
  CUA_DRIVER_RS_ENABLE_WAYLAND = "1";
};
```

Rebuild + restart. Verify:

```bash
systemctl show hermes-agent -p Environment | tr ' ' '\n' | grep CUA
hermes doctor | grep computer_use      # expect ✓
hermes computer-use doctor
```

Then ask the agent to capture a window via `computer_use`. **Decision gate:** if capture fails
with a Wayland/X11 connection error, go to Stage B; if it succeeds, stop.

### Stage B — session environment (only if Stage A fails)

The service has no graphical session env. Add:

```nix
  XDG_RUNTIME_DIR = "/run/user/1000";
  WAYLAND_DISPLAY = "wayland-0";
  DISPLAY = ":0";
```

`wayland-0` is what `cua-driver doctor` reports today; if the compositor's socket changes, this
breaks. Rebuild, restart, retest both from the desktop app and from Discord (different callers,
same process).

### Stage C — fallback (if the sandbox still blocks seat access)

Run the GUI-driving work from a session-scoped process instead of the gateway: the TUI started
inside the niri session inherits `WAYLAND_DISPLAY`, or a `systemd.user` unit with `PartOf` the
graphical session. Document the limitation: "computer_use works from `<surface>`, not from
Discord/cron."

**Why it matters:** Unity Editor dialogs, OBS, and any GUI-only step currently have no tool
path; the agent falls back to CLI/MCP and sometimes cannot complete the step.

---

## Phase 3 — memory solution

The cap is a design feature, not a bug; the problem is that the store is full of facts that
belong in skills, project files, or `fact_store`.

### 3a. Consolidate MEMORY.md (target ≤ 1,650 chars)

Keep (rewritten short):

1. NixOS Hermes layout + `hermes-repair-perms` + pointer to `devops/hermes-state-recovery`.
2. Host tooling: browser text-only, vision works, missing creative apps.
3. Holographic plugin: manual pinned copy, handoff doc path.
4. No pandoc/typst; LibreOffice; `sqlite3` via Python.
5. Privacy project: path + cadence pointer (the plan file holds the detail).
6. Credential rule (keep verbatim — highest value entry).
7. `OBSIDIAN_VAULT_PATH` location.

Move out of MEMORY.md:

- Godot binary path → `fact_store` (project-scoped fact).
- `pm install` / `_copy_core_inputs` sealed bugs → keep one clause in entry 1, drop detail.
- Tool-gap entry → delete once Phases 1–2 land; replace with a dated one-liner only if a gap
  remains.
- Holographic pin/hash detail → already in `docs/holographic-numpy-handoff.md`.

### 3b. Consolidate USER.md (target ≤ 1,150 chars)

- Merge the two "prefers" paragraphs; remove duplicated "agent edits, Chloe activates".
- Delete the garbled fragment `务实的沟通` (corruption, not content).
- Keep: identity/school/languages/skills/links; smallest-viable-fix preference; sudo split;
  script-preview preference; Twitch/audio context; step-by-step session-config preference.

### 3c. Make holographic memory actually searchable

- 19 of 23 facts have no keywords. Run `fact_store enrich` and give each 3–5 keywords,
  including Portuguese/English synonyms.
- Add new durable facts there, not to MEMORY.md: project decisions, tool quirks, preferences
  that are task-scoped.
- Monthly: `fact_store review` during the gremlin sweep (15th).

### 3d. Raise limits only if needed (decision)

If consolidation still leaves frequent rejections, raise in the repo config:

```yaml
memory:
  memory_char_limit: 3000
  user_char_limit: 1600
```

Cost: ~ +370 tokens injected on **every** API call (~1.5M tokens/month at current volume).
Try 1,650/1,150 first; measure for two weeks.

**Done when:** a normal `memory add` succeeds without a prune batch, and `fact_store stats`
shows ≥80% of facts with keywords.

---

## Phase 4 — configuration hygiene

1. **Migrate v41 → v50 against the repo file, not the live one.** Tested in a temp
   `HERMES_HOME`; the entire diff is:

   ```
   _config_version: 41 -> 50
   + connections   (platform_toolsets.cli, and the known-* lists)
   ```

   Commands:

   ```bash
   T=$(mktemp -d)
   cp ~/nixos/modules/config/hermes/config.yaml "$T/config.yaml"
   HERMES_HOME="$T" hermes config migrate
   diff -u ~/nixos/modules/config/hermes/config.yaml "$T/config.yaml"
   ```

   Apply the reviewed diff to the repo file; commit; rebuild.

2. **Resolve the `stt` toolset warning.** `platform_toolsets.cli` lists `stt`, which the config
   does not recognise ("did you mean 'hermes-cli'?"). Decide:
   - if voice input works through `stt.enabled: true` alone → remove `stt` from the toolset
     list;
   - if a toolset is required → use the name migration suggests and verify `hermes tools list`.

3. **Sync `gateway.multiplex_profiles: true`** into the repo (Phase 0).

4. **Leave these off, deliberately:**
   - `image_gen` — no provider/key; adding one is a separate purchase decision.
   - `video_gen` — same.
   - `x_search` — the `xurl` CLI skill already covers X; no `XAI_API_KEY` needed.
   - `a2a` / `browser-cdp` / `feishu_*` / `yuanbao` — unused surfaces.

5. **Browser screenshots:** Lightpanda is text-only by design. Do not switch engines; after
   Phase 2, `computer_use` covers visual checks. If it does not, the fallback is a Playwright
   profile, which is a new dependency — defer.

---

## Phase 5 — verification matrix

Run after the final rebuild, in this order.

| Capability | Command | Pass condition |
|---|---|---|
| Config | `hermes config check` | version 50, no unknown toolset warning |
| Doctor | `hermes doctor` | no ⚠ for tts/computer_use; only optional keys remain |
| TTS | `hermes doctor --live`, then `text_to_speech` | audio file exists, plays |
| computer_use | `hermes computer-use doctor`, then a capture | returns a screenshot path |
| Memory | one `memory add` + remove | add succeeds without prune batch |
| Holographic | `fact_store stats` | structural recall on, keywords ≥80% |
| Browser | `browser_exec` on a JS page | title + body text returned |
| MCP Unity | with editor open | one `execute_code` call succeeds |
| MCP Godot | with editor open | `project_get_settings` succeeds |
| Cron | `cronjob_manage list` | 2 recurring jobs, `last_status: ok` |

---

## Rollback

- Repo: `git -C ~/nixos checkout -- modules/` then rebuild.
- System: `sudo nixos-rebuild switch --rollback`.
- Config/memory: restore the timestamped `.bak` files from Phase 0.
- Record the base revision: `/tmp/hermes-repair-base.rev`.

---

## Sequencing and effort

| Phase | Agent | Chloe | Blocking? |
|---|---|---|---|
| 0 baseline | 10 min | — | yes |
| 1 TTS | 10 min edit | 1 rebuild + test | unblocks vtuber |
| 2 computer_use | 10 min edit | 1–2 rebuilds + GUI test | unblocks GUI steps |
| 3 memory | 30 min | — | unblocks learning |
| 4 config | 15 min | 1 rebuild | hygiene |
| 5 verify | 15 min | — | — |

Total: ~1.5 h of agent work, 2–3 rebuilds.

## Decisions needed from Chloe

1. TTS voice/language: **decided — English (`en-US-AriaNeural`)**.
2. Memory limits: **decided — raise to 3,000/1,600**, with consolidation before adding.
3. computer_use: **decided — Discord yes, cron no**. Cron's `platform_toolsets` list omits it.
4. image_gen: **decided — disabled** (also video_gen, a2a, yuanbao).

## Execution log

### 2026-10-21 — phases 0–4 applied, build pending

- Backups: `~/.hermes/config.yaml.bak-20261021T021129Z`, `MEMORY.md.bak-20261021`,
  `USER.md.bak-20261021`; base revision in `~/.hermes/cache/scratch/hermes-repair-base.rev`.
- `modules/hermes.nix`: `pkgs.piper-tts` added to system packages; the `en_US-amy-medium`
  voice + config fetched by hash and installed under `/etc/hermes/piper/`; gateway unit
  environment set
  (`HERMES_CUA_DRIVER_CMD`, `CUA_DRIVER_RS_ENABLE_WAYLAND`, `XDG_RUNTIME_DIR`,
  `WAYLAND_DISPLAY`, `DISPLAY`).
- `config.yaml`: `tts` (English), memory caps 3000/1600, `_config_version: 50`, `connections`,
  `gateway.multiplex_profiles`, `platform_toolsets.cron` without `computer_use`;
  image_gen/video_gen/a2a/yuanbao removed.
- Memory: MEMORY.md 2,176 → 1,525 chars; USER.md 1,234 → 1,042; Godot path and the
  config-source rule moved to `fact_store`; the detailed tooling record moved to
  `~/wiki/concepts/nixos-hermes-integration.md` (wiki commit `1959392`).
- Remaining: NixOS build result, operator switch, post-switch verification matrix.
