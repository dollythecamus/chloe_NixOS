# Project ledger — nixos host configuration

Updated: 2026-10-22 12:40 (-03) · session local-ac603f060594711b1d97ed3a61663f8ee93493394a8d453a8c575c66d3138968 · owner default
Next review: 2026-10-27

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

One staged change is **not activated** as of this update: `modules/remote-access.nix` (staged, not
committed) sets `PasswordAuthentication = false` and `KbdInteractiveAuthentication = false`, while
the running `/etc/ssh/sshd_config` still has both at `yes` (lines 4 and 8). `~/nixos` is dirty:
2 staged (`docs/phone-access-runbook.md`, `modules/remote-access.nix`), 3 modified
(`flake.lock`, `host_chloe-laptop.nix`, `modules/hermes.nix`), 1 untracked
(`docs/stationeers-hosting-plan.md`); HEAD `cc59d60`.

## Next action

Chloe: commit the pending `~/nixos` paths (2 staged, 3 modified, 1 untracked — see
"Uncommitted at 2026-10-22" below), then
`sudo nixos-rebuild switch --flake ~/nixos#chloe-laptop`. The flake host is confirmed:
`/run/current-system` is `nixos-system-chloe-laptop-26.05.20260719.fd14620`.

**Stopping point:** `grep -iE '^(PasswordAuthentication|KbdInteractiveAuthentication)'
/etc/ssh/sshd_config` shows `no` on both lines and `ssh pc` from the phone still authenticates
by key. Do not start a second change in the same pass.

## Open questions

- ~~Which host config is active: `chloe-laptop`, `-niri`, or `-plasma`?~~ Answered 2026-10-22 —
  `chloe-laptop` (`/run/current-system` →
  `nixos-system-chloe-laptop-26.05.20260719.fd14620`).
- Kanban trial: **go, one week, review 2026-10-29** (Chloe, 2026-10-22). Open sub-question: the
  gateway dispatcher cannot be turned off from config (`hermes config set` refuses — the install is
  nixos-managed), so the only control is keeping the board empty except for approved work. Turning
  `kanban.dispatch_in_gateway` off for a passive trial would need a module line plus a switch.
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
  date 2026-10-29 (one-shot cron job `b3d8ec0e2f3d`).
- 2026-10-22 — **`computer_use` is closed as upstream-blocked, not fixed** (Chloe, explicit).
  Re-verified from this session and from the capture session `20261021_083351_5ae925`: every
  capture mode fails or returns a 0×0 empty AX tree, and there is no local fix available — the
  blocker is in the upstream driver, so this is parked rather than worked around. Nothing in
  `modules/hermes.nix` should chase it again until upstream moves. Remove it from the
  "Done when" matrix rather than leaving it as permanently-red.

## Evidence

- `git -C ~/nixos log --oneline -3` — `4c2334a docs: record repair build result`,
  `b39c791 hermes: local Piper TTS, computer_use gateway env, toolset gating, memory caps`,
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
- 2026-10-22 — `/run/current-system` = `nixos-system-chloe-laptop-26.05.20260719.fd14620`,
  activated 12:11; `stat -c %a /var/lib/hermes/.hermes` → `2750`; `systemctl is-active
  tailscaled` → active, enabled; live `firewall-start` (`/nix/store/6wnqczzg…`) contains
  `dport 27015` and `dport 27016`; `grep -iE '^(PasswordAuthentication|KbdInteractive)'
  /etc/ssh/sshd_config` → both `yes`.
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

Not this workstream, deliberately left untracked: `docs/stationeers-hosting-plan.md` (written
by an earlier session; no review of it in this session).

Already committed by the concurrent session: `modules/config/hermes/config.yaml`,
`modules/hermes.nix`, `docs/hermes-{behavior,tooling-repair}-plan-2026-10-20.md`.

Outside this repo, committed in their own repos: `UnityXR_3DMuseu/docs/PROJECT_LEDGER.md`,
`chloes-2d-library/docs/PROJECT_LEDGER.md`.

## Uncommitted at 2026-10-22 (current)

`git status --porcelain -uall` in `~/nixos`, 6 paths — 2 staged, 3 modified, 1 untracked:
`A  docs/phone-access-runbook.md`, `A  modules/remote-access.nix`, `M  flake.lock`,
`M  host_chloe-laptop.nix`, `M  modules/hermes.nix`, `?? docs/stationeers-hosting-plan.md`.
HEAD `cc59d60 hermes/cua: gdbus on gateway PATH, session bus env for WinRects` (written by a
concurrent session during this pass; `ddd6fcc` was HEAD when the counts were taken).

## Handoff

**Changed (this session):** SOUL source gains a six-rule continuity/routing section;
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
- 2026-10-20 (session 20261020_222629_e4ff94) — goals stated for UnityXR and chloes-2d-library
  → written into both repo ledgers, replacing the README inferences.
