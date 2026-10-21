# Hermes operations plan — dispatch lanes, book-keeping, kanban

Written 2026-10-20. Third of three. Companion to `hermes-behavior-plan-2026-10-20.md`
(prompt + human↔agent protocol) and `hermes-tooling-repair-plan-2026-10-20.md`
(tools, config, memory). This one answers one question: **who does the work, where the
state lives, and what gets logged.**

It does not repeat the other two plans. Where they already specify a mechanism
(`project-ledger` skill, `~/Mind/projects/INDEX.md`, Friday drift cron), this document
only says how that mechanism is fed and who feeds it.

## What changes

| # | Change | Owner | Rebuild |
|---|---|---|---|
| 1 | `SOUL.md` gains a `# Continuity and routing` section (6 rules) | agent edits, Chloe switches | yes — rides the next switch |
| 2 | `project-ledger` skill + template (book-keeping backbone) | agent, runtime | no |
| 3 | `profile-task-dispatch` gains the prompt-budget + dispatch-log contract | agent, runtime | no |
| 4 | Dispatch lanes defined (inline / quick dispatch / board) | this doc | no |
| 5 | Kanban: trial, then keep or drop — decision gate below | Chloe | no |
| 6 | `~/Mind/projects/INDEX.md` portfolio view | staged (behavior plan Change C) | no |

## Verified constraints (2026-10-20)

- **SOUL is declarative.** Source: `~/nixos/modules/config/hermes/SOUL.md`, declared in
  `modules/hermes.nix` → `hermesHomeFiles`, installed at every activation as a real file
  (`install -o chloe -g hermes -m 0640`) at `/var/lib/hermes/.hermes/SOUL.md`. Editing
  `~/.hermes/SOUL.md` is a runtime edit that the next switch reverts. Source and live copy
  were byte-identical before this plan (`diff -q` clean).
- **Profile identities** are declared the same way: `SOUL-{code,nixos,learn}.md`;
  the `nixos` profile's whole config is `config-nixos.yaml`.
- **A SOUL change is not visible until three things happen:** `sudo nixos-rebuild switch`,
  `systemctl restart hermes-agent`, and a new session (the prompt is built per session).
- **Pre-existing drift, not caused here:** live `config.yaml` has
  `gateway.multiplex_profiles: true`, the repo copy does not. Tooling plan Phase 0 owns it;
  the same switch carries it.
- **Profile roster** (`hermes profile list`): `default` (deepseek-v4.1-flash), `code`
  (gpt-6-luna, alias `hcode`), `nixos` (gpt-6-luna), `learn` (deepseek-v4.1-flash). All four
  gateways running.
- **Dispatch cost is real:** one-shot `hermes -p learn chat -q …` cold start measured at
  **23.2 s** for a one-word answer. Process boot + profile SOUL + skills index is paid before
  the task starts.
- **`code`'s subagents** are pinned to `glm-5.3-flash` on `opencode-go`
  (`hermes -p code config get delegation`), so a dispatch to `code` is a model choice too.

## The three lanes

| Lane | Trigger | Mechanism | Cost | Logged as |
|---|---|---|---|---|
| **A — inline** | reasoning, verification, reading, and edits inside a tree I already own; no profile boundary crossed | direct tool calls | cheapest | one ledger line at close |
| **B — quick dispatch** | the slice belongs to another profile's boundary (`code` = repos, `nixos` = system config) and is one prompt's worth of work | `hermes -p <profile> chat -q --query-file <p> -Q`; **no plan file** — 5–10 lines derived from the ask, absolute paths, hard limits, required report | ~25 s + run | one ledger line: date · profile · ask · session id · verdict |
| **C — board** | more than one step, has dependencies, must survive this session, or needs a human checkpoint | Kanban card(s); gateway dispatcher picks them up on a 60 s tick | full worker boot per card | the card itself, plus one ledger line on completion |

**Lane B is the default for authoring work, not the exception.** If Chloe asks for something
that lands in a repo or in `~/nixos`, the work goes to that profile even when it is small —
the mobile mental model is "ask, and it is routed", not "small things stay here".

**Thresholds live in the skill, not in SOUL.** The lane boundary and the lane-C trigger are
editable at runtime (`profile-task-dispatch`); SOUL carries only the invariants. This keeps
policy tuning off the rebuild path.

**Lane A still exists for one reason:** an orchestrator that cannot read a file, run a test,
or diff a tree cannot verify a worker's report, and a worker's report is a claim, not
evidence.

## Book-keeping layers — one job each

| Layer | Question it answers | Where | Update cadence |
|---|---|---|---|
| Plan | what *should* happen | `docs/*plan*.md`, `~/online-privacy/plan.md`, `~/Mind/projects/*` | written once, revised rarely |
| Ledger | what is *true now* | `<project>/docs/PROJECT_LEDGER.md` | every session that touches the project |
| Board | what is *queued / in flight* | kanban (if adopted) | dispatcher + workers |
| Index | what exists, when it was last touched | `~/Mind/projects/INDEX.md` | weekly |
| Drift alarm | what has gone quiet | Friday cron (behavior plan E1) | weekly, report-only |

**Non-duplication rule.** Plan = intent · ledger = state · board = queue · index = links.
Status is written in exactly one of them — the ledger — and everything else points at it.
A card that finishes writes one line into its project ledger; it does not carry the project's
status.

**Why the abandoned-project problem is a logging problem, not a memory problem.** A project
stops being visible the moment its only trace is a chat session. The ledger makes "last
verified" a date on disk; the index makes the project appear in the portfolio view; the cron
makes silence itself the alarm. None of the three requires anyone to remember.

## Kanban briefing — what committing would actually mean

**What it is.** A SQLite task board shared across profiles. Cards move triage → todo → ready →
running → review → done/blocked. A dispatcher **inside the gateway** (`dispatch_in_gateway:
true`, 60 s tick, `failure_limit: 2`, `review_dispatch: true`) atomically claims ready cards
and spawns the assigned profile in an isolated workspace. Workers get a `kanban_*`-only
toolset (show, complete, block, heartbeat, comment, create, link, attach…) and never see the
CLI or the dashboard.

**State on this machine right now:** board `default` exists and is empty
(`hermes kanban stats` → all columns 0). Nothing has ever run on it.

**What it buys that a ledger cannot:**

- queue semantics — a card is claimable, so parallel work does not collide;
- durability — survives gateway restarts and app closes (`dispatch_stale_timeout_seconds:
  14400` before a claim is reclaimed);
- an audit trail — every card keeps events, comments, runs, artifacts;
- review gates — `request-review` / `request-changes`, useful before trusting a worker;
- the swarm primitive: `hermes kanban swarm <goal> --worker code:… --worker nixos:…
  --verifier default --synthesizer default` builds workers → verifier → synthesizer as one
  graph. That is the "communicating team" shape you said you are in favour of, and it is one
  command rather than a custom harness.

**What it costs, concretely:**

- every card is a full agent process — cold boot plus that profile's SOUL, skills, memory,
  and its own model (`code`/`nixos` = gpt-6-luna). Ten small cards is ten boots, not one;
- `scratch` workspaces are disposable: only declared artifacts survive, so a card that edits
  a repo must use `--workspace dir:<path>` or `--workspace worktree`;
- `auto_decompose: true` means any card parked in triage gets rewritten into child cards by
  an auxiliary model (up to 3 per tick). Useful for goals, noisy for errands. Turn it off
  (`kanban.auto_decompose: false`) and use `specify`/`decompose` on demand if that bites;
- the dashboard page is documented, but I did not confirm it is served on this install — the
  CLI is the surface I can vouch for today.

**The real risk.** The board becomes a second place to forget things: cards rot in `todo`,
and now two systems disagree about what is current. That is why the trial has a decision
gate instead of an adoption date.

### Trial — three useful cards, not a demo

All three are real work already owed by the tooling plan, and all three produce content for
the first ledgers. Nothing here needs sudo.

```bash
# 1. nixos profile: resolve the edge-tts version in the pinned nixpkgs (tooling plan Phase 1)
hermes kanban create "Resolve edge-tts version in pinned nixpkgs" \
  --assignee nixos --workspace scratch --max-runtime 10m \
  --body "Run: nix eval --raw nixpkgs#python3Packages.edge-tts.version (pinned flake input of ~/nixos). Report the exact version string and the flake input it came from. No edits, no sudo."

# 2. code profile: inventory the uncommitted work (behavior plan, 53 files)
hermes kanban create "Inventory uncommitted work in UnityXR and chloes-2d-library" \
  --assignee code --workspace dir:/home/chloe --max-runtime 20m \
  --body "For /home/chloe/projects/UnityXR_3DMuseu and /home/chloe/projects/chloes-2d-library: git status --short, git diff --stat, and per repo one line naming the branch and whether it is ahead/behind. Write nothing, commit nothing. Report the two inventories verbatim."

# 3. verifier: re-check both artifacts (me)
hermes kanban create "Verify tooling-trial artifacts" \
  --assignee default --parent <card1> --parent <card2> \
  --body "Re-run the version eval yourself and re-run git status in both repos. Report pass/fail per card and any disagreement with the worker's report."
```

**Decision gate — keep kanban only if all three hold after the trial:**

1. the board is actually consulted (you open it, or ask "what's in flight?") at least twice
   in the first week;
2. cards reach `done` without manual prodding — the dispatcher works unattended;
3. the board *replaces* ledger status lines rather than duplicating them.

If those fail, drop the board, keep the ledger + Friday cron, and the only loss is the queue.
That is a cheap failure mode — which is the point of trialling instead of adopting.

## Sequencing against the other two plans

| Order | Item | From | Rebuild |
|---|---|---|---|
| 1 | SOUL `# Continuity and routing` | this plan | rides #4 below |
| 2 | `project-ledger` skill + template | behavior B | no |
| 3 | `profile-task-dispatch` contract patch | this plan | no |
| 4 | Next switch: SOUL install + tooling phases (TTS, CUA, config hygiene) | behavior A + tooling 1/2/4 | **one switch** |
| 5 | Kanban trial (3 cards) | this plan | no |
| 6 | `~/Mind/projects/INDEX.md` + Friday cron | behavior C/E1 | no |
| 7 | Two-week metric review (2026-11-03) | behavior | — |

One switch carries every file-level identity and config change; the runtime work (skill,
patch, trial, index, cron) needs nothing.

## Decisions needed from Chloe

1. **Lane B default** — confirm that authoring work goes to the owning profile even when it is
   small, with only pure reasoning/verification staying inline.
2. **Kanban trial** — run the three cards now, after reading, or not at all.
3. **Ledger scope** — every project, or only multi-session ones (behavior plan recommends
   multi-session only).

## What this plan deliberately does not do

- It does not put kanban into SOUL. The board is a candidate, and a rebuild should not be the
  price of dropping it.
- It does not create a second status system. The ledger stays authoritative.
- It does not automate the ledger from git. Git records changes; it does not record intent,
  and a ledger built from `git log` would describe motion instead of progress.
