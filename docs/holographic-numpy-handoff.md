# Handoff: restore full `holographic` memory recall (numpy) after the left-core update

Written 2026-10-12 by the TUI session. Target files: `~/nixos/flake.lock` (via
`nix flake update`) and `~/nixos/modules/hermes.nix`. Chloe runs the switch herself;
you (the config agent) edit config / flake and build.

## Background (state as of 2026-10-12)

- An update moved the bundled memory provider `holographic` out of hermes-agent core into a
  community catalog plugin (`itpartypattaya/hermes-plugin-holographic`). Hermes's auto-migration
  tried `hermes plugins install holographic` and died on the sealed-NixOS layout: PM's venv
  sync hashes `repo_root()/uv.lock` (`pm/packages.py:383`), but the sealed site-packages dir
  (`9s0pwx…-hermes-agent-0.0.0/lib/python3.14/site-packages`) ships no `uv.lock` (it lives in
  the separate `-hermes-python-source` derivation).
- WORKAROUND ALREADY IN PLACE: the plugin was cloned at the catalog's reviewed pin
  (`46b6f9084bd6ebd13262fb2360f3314c352f4be8`, v0.6.1, includes `.git`) into
  `/var/lib/hermes/.hermes/plugins/holographic`, which user-plugin discovery picks up without PM
  metadata. `hermes memory status` shows installed/available; the startup warning is gone and
  its backoff stamp (`cache/left-core-holographic.failed`) was removed.
- REMAINING GAP: the plugin's `pyproject.toml` declares `numpy` + `snowballstemmer`.
  `snowballstemmer` is already in the sealed venv; **numpy is NOT**
  (verified against runtime venv `gh6mx20…-hermes-agent-env`). Effect: `fact_store stats`
  self-reports `structural_recall: "off (numpy missing)"` — keyword recall works; HRR
  structural `related`/`reason` recall is degraded.

## Mechanism you will use (verified in hermes source at 53bc70c5)

- `services.hermes-agent.extraPythonPackages` (`nix/moduleCommon.nix:440`,
  `types.listOf types.package`): when non-empty, `moduleCommon.nix:681` calls
  `cfg.package.override { inherit extraPythonPackages extraDependencyGroups; }`, and
  `nix/hermes-agent.nix` builds `allExtraPythonPackages = python.pkgs.requiredPythonModules …`,
  appends `--suffix PYTHONPATH` to EVERY agent wrapper (gateway + TUI + desktop), and fails the
  build if an extra collides with a core venv package.
- The interpreter is derived from `pm/lock.json` by `nix/pythonLock.nix` and exposed as
  `services.hermes-agent.package.python` (passthru), whose `.pkgs` set matches that interpreter.

## Step 1 — update the flake input

```bash
cd ~/nixos
nix flake update hermes-agent
git diff flake.lock        # confirm only hermes-agent (and its pinned inputs) moved
```

Current pin: `53bc70c5ee8544040cd9f0708d25c0f55276a44b` ("v0.0.0 (2026.9.24)", 66 commits
behind upstream main).

### Re-check interfaces against the NEW revision before proceeding

Option declarations and the nix packaging live in the hermes-agent repo
(`nix/moduleCommon.nix`, `nix/hermes-agent.nix`, `nix/nixosModules.nix`):

1. `extraPythonPackages` still exists with the shape above.
2. `package` still exposes passthru `python` (`nix/hermes-agent.nix` passthru block, ~line 300
   at `53bc70c5`) so `package.python.pkgs.numpy` resolves.
3. Whether the sealed package now ships `uv.lock` beside `site-packages` (upstream may have
   fixed the bundled-provider migration bug — that changes Step 5).

If any interface changed, adapt to the new names; do not guess.

## Step 2 — add numpy via extraPythonPackages

Edit `~/nixos/modules/hermes.nix`, inside `services.hermes-agent` (next to the existing
`extraDependencyGroups`), add:

```nix
    # numpy for the holographic memory plugin (2026-10-12 handoff:
    # docs/holographic-numpy-handoff.md) — went PYTHONPATH, sealed-side.
    extraPythonPackages = [
      config.services.hermes-agent.package.python.pkgs.numpy
    ];
```

Rules:

- Use `config.services.hermes-agent.package.python.pkgs.numpy` — NEVER
  `pkgs.python314Packages.numpy` or any nixpkgs-python-set shortcut. The lockfile pins the
  interpreter version; a numpy built against the wrong interpreter is exactly the failure mode
  this option exists to prevent.
- Note on `requiredPythonModules`: the derivation wraps `requiredPythonModules extraPythonPackages`,
  so one package is enough — numpy's transitive deps (none beyond stdlib for numpy) are not
  your concern.
- If the build's collision check errors on numpy, STOP and report — that would mean upstream
  added numpy to core since; remove the option instead of working around it.

## Step 3 — build (you), switch (Chloe)

```bash
cd ~/nixos
git add -A                                   # untracked files fail the flake build
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

Chloe then runs `sudo nixos-rebuild switch --flake ~/nixos#<host>` in her own terminal.

## Step 4 — verify after the switch

Record the new store path first (`NP=$(readlink -f /run/current-system/sw/bin/hermes)`).

1. `hermes --version` → newer than `v0.0.0 (2026.9.24) · upstream 53bc70c5`.
2. Numpy resolves through the ACTUAL wrapper (PYTHONPATH is only appended there, so a probe
   must go through `hermes …/bin/hermes` or replicate its `--suffix PYTHONPATH`; find the
   suffix with `grep -a PYTHONPATH $NP/bin/hermes` or inspect the wrapped env):

   ```bash
   HERMES_HOME=/var/lib/hermes/.hermes \
   $NP/bin/hermes chat -q "reply with just: ok"   # cheap warm-path check first
   ```

   If a `-q` round trip is undesirable, test directly: take the PYTHONPATH value found inside
   the wrapper and run
   `PYTHONPATH=<value> /nix/store/*-hermes-agent-env/bin/python3.14 -c "import numpy; print(numpy.__version__)"`
   → expect a version printed, no traceback.
3. `hermes memory status` → Provider: holographic, Plugin: installed ✓, Status: available ✓,
   `holographic (local) ← active` in the list.
4. Structural recall self-report (decisive check):

   ```python
   import os
   os.environ["HERMES_HOME"] = "/var/lib/hermes/.hermes"
   os.environ["PYTHONPATH"] = "<PYTHONPATH from the wrapper>"   # plus new site-packages
   from plugins.memory import load_memory_provider
   p = load_memory_provider("holographic")
   out = p.handle_tool_call("fact_store", {"action": "stats"})
   print(out)   # expect structural_recall ON; database unchanged at memory_store.db
   ```

   Run under `/nix/store/gh6mx20…-hermes-agent-env/bin/python3.14` or the new build's
   equivalent. Before this fix the same call printed `"off (numpy missing)"`.
5. A real end-to-end fact use (optional but best): ask the agent in chat to
   `fact_store search` for a known fact and confirm results + `#id` feedback flow work.

## Step 5 — reconcile manual copy vs official PM install (conditional)

Only if BOTH hold on the new build:

- `ls <pkgdir>/site-packages/uv.lock` exists (upstream packaging fix), AND
- `hermes plugins install holographic` itself exits 0 (not just "already exists" errors).

Then replace the manual copy with the PM-managed install it provides (catalog pin metadata,
official updates):

```bash
hermes plugins install holographic --force
```

If only one holds, keep the manual copy as-is and note it in this file — no hybrid surgery.
If neither holds (uv.lock still missing), the manual copy remains the standing mechanism;
numpy via PYTHONPATH is still the complete fix.

## Do not

- Do not run `hermes pm install` expecting venv syncs to work on the sealed layout
  (FileNotFoundError: `<pkgdir>/.../uv.lock` — documented in `godot-mcp-handoff.md`).
- Do not add numpy by editing `. burden` inside the read-only store, bind-mounts, or symlinks
  into `site-packages` — extraPythonPackages is the supported, build-time-verified surface.
- Do not touch `memory.provider`, `plugins.hermes-memory-store`, or
  `/var/lib/hermes/.hermes/memory_store.db`: the plugin keeps the same provider name, config
  keys and DB as the old bundled provider; those are correct already.

## Rollback

- extraPythonPackages: delete the lines, rebuild, switch. Purely additive otherwise.
- Manual plugin copy: runtime state, not affected by switches. Removing it returns the
  startup warning until `memory.provider` is changed (edit source
  `~/nixos/modules/config/hermes/config.yaml`, `memory.provider:` — or run Chloe's declared
  alternative) — coordinate before deleting.

---

## Status (2026-10-12, executed — pre-switch work complete)

- Step 1 done: input updated `53bc70c5` → `53df274b`; diff touches only hermes-agent.
  Interfaces re-verified at the new rev: `extraPythonPackages` unchanged
  (moduleCommon.nix:440, override at 681-684); passthru `python` present
  (hermes-agent.nix:306); sealed `site-packages/uv.lock` still ABSENT.
- Step 2 done: `extraPythonPackages = [ config.services.hermes-agent.package.python.pkgs.numpy ]`
  added in `modules/hermes.nix` (numpy resolves to python3.14-numpy-2.5.2 for the
  pm/lock.json interpreter).
- Step 3 done: top-level build exit 0; wrapper for the built system appends the numpy
  site-packages path to PYTHONPATH on every invocation; import probe through the wrapper's
  exact PYTHONPATH with the lockfile interpreter prints `numpy OK 2.5.2`.
- Commit in ~/nixos: `bb4c305` (hermes: supply numpy to the holographic memory plugin).
- Step 5 resolution (decided now): site-packages/uv.lock still missing in the new build's
  hermes-agent-env → only the second condition can never hold → manual pinned copy STAYS
  the standing mechanism; no `hermes plugins install` attempt was made.
- Steps 1,2 of verification list (post-switch, Chloe): `hermes --version` newer than
  53bc70c5; `hermes memory status`; fact_store stats structural_recall. The bare-python
  probe of `load_memory_provider("holographic")` returns None pre-bootstrap (community
  plugin registration is runtime-only), so the decisive structural check needs the switch.
