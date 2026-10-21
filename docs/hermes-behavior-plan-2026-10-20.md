# Hermes behavior plan — long-horizon continuity and communication

Written 2026-10-20. Scope: the system prompt and the human↔agent protocol. Tool and config
repairs are in `hermes-tooling-repair-plan-2026-10-20.md`.

## What actually failed (evidence, 2026-09-17 → 2026-10-20)

| Failure | Evidence | Root cause |
|---|---|---|
| Requirements lost across sessions | 3 features asked 2026-10-13 (panel height adjust + 2) missing from the plan until a 2026-10-19 audit recovered them from chat history | New asks live in chat, not in a file the next session reads |
| No checkpoint before a session dies | 21/68 sessions ended `startup_orphan_reap`; no per-session handoff exists | The prompt says "don't stop early", nothing says "record state before you stop" |
| Work not durable | 53 modified files uncommitted across UnityXR (16) and chloes-2d-library (37) | "Done" is defined as verified output, not committed output |
| Session sprawl | One animation fix ran 690 messages / 372 tool calls | No stopping condition, no scope restatement on "continue" |
| Plans don't reach the daily list | `~/Mind/do now.md` links only the job-hunt plan; privacy/game-jam/server plans are unreferenced | Plans are written for an executor, never indexed for the human |

These are not model-capability failures. They are missing conventions.

## Design principles

1. **Append, don't remember.** If a requirement is not written into the project, it does not
   exist next session.
2. **One ledger per project.** The plan says what should happen; the ledger says what is true
   now.
3. **Checkpoint at boundaries, not at death.** Write state before a switch, a long run, or a
   likely app close — not at session end.
4. **Commit is part of done.** A deliverable that is not committed is listed as at risk.
5. **Restate scope on short commands.** "Continue" is not a specification.

---

## Change A — SOUL.md additions (highest leverage)

Source of truth: `~/nixos/modules/config/hermes/SOUL.md` (installed at activation; editing
`~/.hermes/SOUL.md` reverts). Append one section, ~600 chars:

```markdown
## Long-horizon work

- Every project that spans more than one session keeps `docs/PROJECT_LEDGER.md`: goal, status,
  one next action, open questions, decisions, last verified, uncommitted files.
- New requirements are appended to that ledger in the same turn they arrive, dated, with the
  session id. Chat is not storage.
- Before switching tasks, ending a session, or handing off: update the ledger, write the
  handoff, and commit or list every uncommitted file.
- On "continue", restate the scope in one line and name the stopping point before acting.
```

Why this shape: it is four rules, all observable, and it costs ~150 tokens per turn. It does
not change the existing voice or verification rules.

Optional fifth line, if the first two weeks show over-long sessions:

```markdown
- Stop and report when a task exceeds ~150 tool calls without a verified milestone.
```

---

## Change B — `project-ledger` skill

Create with `skill_manage` (description must be **≤ 60 chars** — that limit rejected 9 saves
historically):

- name: `project-ledger`
- description: `Use when a project spans sessions: ledger, checkpoints.` (57 chars)
- category: `productivity`

Body contents:

1. **Template** (`templates/PROJECT_LEDGER.md`):

   ```markdown
   # Project ledger — <name>
   Updated: YYYY-MM-DD HH:MM (-03) · session <id>
   Goal:
   Done when (observable):
   Status: active | paused | blocked | done
   Next action (one):
   Open questions:
   Decisions: YYYY-MM-DD — decision — why
   Evidence: file:line / command / URL
   Uncommitted at last checkpoint: <files or "none">
   ```

2. **Resume procedure** (run before any work on an existing project):
   read ledger → read the plan it points at → `git status` → verify the last claim against
   live state → state the next action and the stopping point → then act.

3. **Close procedure:** update ledger → write handoff (what changed, what was verified, what
   is next) → commit or list → only then report done.

4. **Pitfall to encode:** a ledger status is a claim, not evidence. Re-verify cheaply before
   trusting it (the Stationeers rebuild was caught only because the live firewall script was
   read directly).

---

## Change C — surface the plans for the human

1. Create `~/Mind/projects/INDEX.md` with one row per project:

   | Project | Plan | Ledger | Status | Next review |
   |---|---|---|---|---|

   Seed with: UnityXR, magical-collector, chloes-2d-library, terminal-vtuber,
   online-privacy, game-jam experiment, computer_setup, job hunt.

2. Add one line at the top of `~/Mind/do now.md`:

   ```markdown
   Project board: [[projects/INDEX]]
   ```

3. Keep `do now.md` as the *daily* list; the index is the *portfolio* view. Do not duplicate
   status in both — the index links, the daily list chooses.

**Done when:** every active project appears in the index with a plan link and a next review
date, and the privacy plan's Phase 1 date (2026-10-22) is either met or explicitly moved.

---

## Change D — communication protocol (both directions)

### D1. Agent obligations (put in the skill, not SOUL)

- **Skill activation is the agent's job, not the user's.** If a request matches a skill, load it
  without being asked; the user should never have to remember that a skill exists. State which
  skill was loaded only when it changes the answer.
- At task start, if "done" is not observable, ask one question: *what should I see when this
  is right?*
- On terse commands, restate scope in one line before acting.
- On multi-ask messages, enumerate each ask as its own todo item.
- At the end of visual/debug work, report **what was checked** and **what was not**.

### D2. Chloe's templates (one page, optional)

Start a task:

```
Goal:
Done when (what I will see):
Constraints (don't touch / no push / time limit):
Where: @file / @folder
```

Continue:

```
Continue <scope>. Stop at <boundary>. Checkpoint first.
```

Stop / switch:

```
Checkpoint and handoff now; commit what is safe; list the rest.
```

These are not bureaucracy: each maps to a failure above. The start template fixes late
acceptance criteria; the continue template fixes scope drift; the stop template fixes the 21
orphan-reaped sessions.

### D3. Language rule

Academic/UNICAP deliverables in Portuguese; engineering chat and commit messages in English.
Already the de-facto pattern — make it explicit so output language is never guessed.

---

## Change E — cadence

### E1. Weekly plan audit (new cron)

- Schedule: Friday 17:00, deliver Discord.
- Prompt: read `~/Mind/projects/INDEX.md` and every ledger; report only (a) status changes
  since last week, (b) projects with no activity >7 days, (c) plans whose dated target passed,
  (d) one next action per active project. Do not edit files.
- Rationale: the existing Monday/Saturday digests cover news and learning, not project drift.

### E2. Monthly memory hygiene

Fold into the existing gremlin sweep (15th): `fact_store review`, merge duplicates, prune
MEMORY.md back under budget. Detail lives in the tooling plan, Phase 3.

---

## Metrics — two-week trial

| Metric | Baseline (33 days) | Target |
|---|---|---|
| Cross-session requirement loss | 1 incident, 3 features | 0 |
| Sessions with a handoff/checkpoint | 0 conventional | ≥ 80% |
| Uncommitted files older than 24 h | 53 | 0 |
| Longest single-feature session | 690 messages | < 250 |
| User corrections ("still/not working") | ~10 across 68 sessions | ≤ 3 |

Review on 2026-11-03. Keep what moved; drop what did not. Do not add more rules to compensate.

---

## Rollout

| Day | Action | Owner |
|---|---|---|
| 1 | Add SOUL section; rebuild | agent edits, Chloe switches |
| 1 | Create ledgers for UnityXR + chloes-2d-library; commit the 53 files | agent |
| 3 | Create `project-ledger` skill + template | agent |
| 5 | Create `~/Mind/projects/INDEX.md`, link from `do now.md` | agent |
| 7 | Add Friday audit cron | agent |
| 14 | Metric review | both |

---

## Decisions needed from Chloe

1. Ledger for **all** projects, or only multi-session ones? (Recommendation: multi-session
   only; a one-evening jam does not need a ledger.)
2. Friday 17:00 audit — keep, or move to Sunday evening?
3. Do you want the D2 templates as a note in `~/Mind`, or is the protocol enough in the skill?
4. Is the 150-tool-call stopping rule wanted, or is that too rigid?

## What this plan deliberately does not do

- It does not make the ledger a second plan document. Plan = intent; ledger = state.
- It does not automate status from git alone — git shows changes, not intent.
- It does not add prose to SOUL beyond the four rules; the prompt is already 18k chars.
