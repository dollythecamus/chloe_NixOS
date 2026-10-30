# AGENTS.md — working rules for this repo

NixOS flake for one host, `chloe-laptop`. Four outputs share every module and differ only
by the `desktop` specialArg (`gnome`, `niri`, `plasma`, `xfce`). Read
[ARCHITECTURE.md](ARCHITECTURE.md) before changing module structure.

## Commands (all verified 2026-10-30 unless marked)

Evaluation needs a writable `XDG_CACHE_HOME`: the Nix daemon's own `~/.cache/nix` is
root-owned, and eval dies without it.

```bash
export XDG_CACHE_HOME=$HOME/.hermes/cache/scratch/nixcache   # mkdir -p first
```

| Purpose | Command |
|---|---|
| Eval one output | `nix eval --raw .#nixosConfigurations.<out>.config.system.build.toplevel.drvPath` |
| Eval all four | `for o in chloe-laptop chloe-laptop-niri chloe-laptop-plasma chloe-laptop-xfce; do nix eval --raw ".#nixosConfigurations.$o.config.system.build.toplevel.drvPath"; done` |
| Cost of the next switch | `nix build --dry-run .#nixosConfigurations.chloe-laptop.config.system.build.toplevel` (reports `N derivations will be built` + `M paths will be fetched`) |
| One evaluated option | `nix eval --json .#nixosConfigurations.<out>.config.<option.path>` |
| What is actually live | `nix-store -q --deriver "$(readlink -f /run/current-system)"` and `stat -c %y /run/current-system` |
| Whitespace gate | `git diff HEAD --check` |
| Hermes config sanity | `HERMES_HOME=/var/lib/hermes/.hermes hermes config check` |
| Switch (**Chloe only**) | `sudo nixos-rebuild switch --flake ~/nixos#chloe-laptop` |

Expected shapes, not counts: every output must eval to a `nixos-system-chloe-laptop-*.drv`
path; `git diff HEAD --check` prints nothing; the live deriver equals the drvPath the tree
evaluates to only after a switch, never before.

## Permission boundaries

- **Agent may**: edit this repo, eval, dry-build, run `git add <explicit paths>` + commit,
  read live state under `/var/lib/hermes` and `/etc`.
- **Agent must not**: run `sudo` or `nixos-rebuild switch`; write `/var/lib/hermes/.hermes/*`
  that activation regenerates (config.yaml, SOUL.md, ETHOS.md, `.container-mode`); read or
  commit secret values (`/run/agenix/*` is root-only — those live in agenix, never here).
- **Ask first**: a change that touches more than one output when only one is requested,
  anything that relaxes access control (`-ac`, `PasswordAuthentication`, firewall), and any
  new module file.

## Done criteria

1. All four outputs evaluate after the edit (`evaluate` table above), or the change is stated
   as single-output with the reason.
2. Every claim in the report is backed by a command output, not by the diff looking right.
3. `docs/PROJECT_LEDGER.md` updated: state, next action, evidence, uncommitted list.
4. Commits split by workstream; the ledger commit is last, and no commit names its own sha.

## Conventions

- Hermes config is source of truth in `modules/config/hermes/`; it is installed at activation,
  so runtime edits to `~/.hermes` are reverted by the next switch.
- Agent state is `/var/lib/hermes/.hermes`, bridged by `~/.hermes` (a symlink recreated by the
  `hermes-home-bridge` activation script).
- Commit author for agent commits: `git -c user.name=Hermes -c user.email=hermes@localhost commit`.
- Stage explicit paths. There is no `git config user.*` here, and anything already in the
  index (a leftover `git add` from an earlier session) is swept into the next commit — read
  `git status --porcelain` before committing.

## Pitfalls

- **Repo file ≠ live system.** A committed module is not active until the switch runs. Compare
  `/run/current-system`'s deriver, or the generated file in `/etc`, never the `.nix` source.
- **Build artifacts in the repo root**: `result` is git-ignored; `nixos-switch.log` is *tracked*
  and accrues raw switch output. Do not stage it by accident — commit it deliberately or not at all.
- **`desktop` gating is load-bearing**: a module that branches on `desktop` must handle all four
  values, including `xfce`, and `home/chloe.nix` + `home/home-programs.nix` + `modules/cua-driver.nix`
  + `modules/hermes.nix` all branch on it.
