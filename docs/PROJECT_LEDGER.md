# Project ledger — nixos host configuration

Updated: 2026-10-20 23:52 (-03) · session 20261020_222629_e4ff94 · owner default
Next review: 2026-10-27

## Goal

The host builds from `~/nixos` and every capability it declares actually works: one
declarative source for system config, Hermes identity, and the agent's operating rules.

## Done when

- `sudo nixos-rebuild switch --flake ~/nixos#<host>` succeeds and the running system matches
  the built store path already produced by the tooling session.
- `/var/lib/hermes/.hermes/SOUL.md` matches `modules/config/hermes/SOUL.md` (diff clean).
- The tooling plan's verification matrix passes with **real calls**: TTS, computer_use, memory
  write, browser, MCP.

## Status

active — repo is committed and **builds exit 0**; the operator switch has not run, so live
state lags by one activation (`hermes config check`: live v41 → repo v50; live SOUL 1832 B vs
repo 2898 B).

## Next action

Chloe: `sudo nixos-rebuild switch --flake ~/nixos#chloe-laptop` (or `#chloe-laptop-niri` if
that is the active session), then `systemctl restart hermes-agent`.

**Stopping point:** after the switch — one `diff` of live vs source SOUL, one `config check`
showing v50, and one real `text_to_speech` call. No further rebuilds in the same pass.

## Open questions

- Which host config is active: `chloe-laptop` (gnome), `-niri`, or `-plasma`? Affects where the
  CUA/mission-control env actually lands.
- Kanban trial go/no-go (briefing in the operations plan; decision still pending).
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

## Evidence

- `git -C ~/nixos log --oneline -3` — `4c2334a docs: record repair build result`,
  `b39c791 hermes: local Piper TTS, computer_use gateway env, toolset gating, memory caps`,
  `94c8a9d networked`.
- Build result (from the committed plan): exit 0,
  `/nix/store/90lzjkk5slkgr5rj1sk5mfg2wd313a09-nixos-system-chloe-laptop-26.05.20260719.fd14620`.
- `diff -q /var/lib/hermes/.hermes/SOUL.md modules/config/hermes/SOUL.md` — DIFFERS; live is
  still 1832 B, repo is 2898 B (10 rules vs 6).
- `hermes config check` — live v41, repo v50.
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

**NOT verified:** nothing here has been through a switch — live SOUL, live config (v41), the
Piper voice, and the CUA environment are all untested on the running system; the kanban trial
has not run; the `code` profile has no `project-ledger` skill installed (the template was given
inline).

**Next:** the switch, then the four real-call checks above. If `text_to_speech` fails, the
committed plan's Piper note is the first place to read.

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
