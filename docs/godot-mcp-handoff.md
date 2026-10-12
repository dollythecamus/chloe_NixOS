# Handoff: enable godot-mcp (and native MCP servers generally) on the NixOS Hermes install

Written 2026-10-12 by the magical-collector session. Target file: `~/nixos/modules/hermes.nix` (module for `services.hermes-agent`), flake at `~/nixos/flake.nix`.

## Correction to the original assumption (read first)

The instinct "install the `mcp` python extra via a nix change" is **not needed**:

- The sealed venv (`/nix/store/7f5i…-hermes-agent-env`) already contains `mcp==2.0.0`, `httpx2`, `starlette` — upstream `[all]` dependency group already includes `hermes-agent[mcp]` (see `pyproject.toml` lines ~505 in the hermes-agent source).
- The earlier `python3 -c "import mcp"` failure was tested with the WRONG interpreter (the system 3.13, not `HERMES_PYTHON`). Verify with:
  `/nix/store/7f5i58kap28gyw2ys8pm8p5f6i6qvqgx-hermes-agent-env/bin/python3 -c "import mcp; print(mcp.__file__)"` → works.

godot-mcp itself is a **Node** MCP server, launched via `npx -y github:Coding-Solo/godot-mcp`. Node (`/nix/store/nsj8…-nodejs-26-npm-12/bin`) is already in the hermes-agent runtimeDeps closure. **No Nix package install is required.** The only change is declarative config.

## Change 1 (required): add the server to the declared config

The gateway config is declared at `~/nixos/modules/config/hermes/config.yaml` (`configFile` in hermes.nix). Runtime `hermes config set` edits get reverted on the next switch, so edit the source file. Add:

```yaml
mcp_servers:
  godot:
    command: "npx"
    args: ["-y", "github:Coding-Solo/godot-mcp"]
    env:
      GODOT_PATH: "/run/current-system/sw/bin/godot"
    timeout: 120        # scene ops can be slow
    connect_timeout: 60
```

Notes:
- The env filter strips everything except a safe baseline (PATH, HOME, …), so `GODOT_PATH` MUST be passed via `env` — do not rely on the shell PATH alone. Point it at the system path rather than `/home/chloe/.nix-profile/...` so the gateway (running as chloe) and any profile resolve the same binary. Godot 4.6.3 is installed per-user at `/etc/profiles/per-user/chloe/bin/godot` → confirm it's also on `/run/current-system/sw/bin/godot` via `addToSystemPackages`/`environment.systemPackages`; if not, run `nix eval /home/chloe/nixos#nixosConfigurations.<host>.config.environment.systemPackages` or just use the per-user absolute path.
- Server name `godot` → tools registered as `mcp_godot_*` (e.g. `mcp_godot_launch_editor`, `mcp_godot_run_project`, `mcp_godot_get_godot_version`).

Alternative (module-level, if a per-declared-server approach is preferred): none exists — `mcp_servers` is only config.yaml content. Keep it in `configFile`.

## Change 2 (optional hygiene): nothing else

- `extraDependencyGroups = ["messaging" "anthropic"]` in hermes.nix can stay as is; `mcp` is inside `[all]` and already sealed in.
- Do NOT add `extraPythonPackages = [ pkgs.someMcpThing ]`; unnecessary.

## Verify after rebuild (owner of change runs the switch)

1. Rebuild + switch (usual flow: Chloe runs the switch herself, agent edits + `nix build`).
2. `hermes doctor` → "No suspicious MCP stdio commands", no MCP connection errors.
3. In a fresh agent session: tool list contains `mcp_godot_get_godot_version`; call it — expect `4.6.3`.
4. `mcp_godot_list_projects "/home/chloe/projects"` should find `magical-collector`.

## Upstream bugs found while investigating (report upstream, not blockers)

Found against `fe771090` (0.0.0 sealed nixos build), all reproducible, none needed for godot-mcp:

1. **`hermes pm install <anything>` crashes on sealed-nixos installs** with
   `FileNotFoundError: <pkgdir>/lib/python3.14/site-packages/uv.lock`.
   The `Venv.expected_stamp()` (`pm/packages.py:383`) hashes `project_root()/uv.lock`, but `pm.paths.repo_root()` resolves to the SEALED site-packages dir, which doesn't ship `uv.lock` (it ships in the separate `-hermes-python-source` derivation). Any `hermes pm` venv-sync on this layout is dead — a real landmine for future `hermes pm install agent-browser`/provider-extras commands.
2. **`_copy_core_inputs` preserves read-only modes** (`pm/workspace.py:109`, `shutil.copy2`): when the project_root is the nix store source tree, the copied `pyproject.toml` lands 0444 and `_generate_pyproject`→`write_text` then EACCESes. Fix upstream: `shutil.copy2(...)` → copy then `os.chmod(target, 0o644)` (or `shutil.copyfile` + explicit chmod — "build from a writable snapshot, never from signed/read-only source" is literally the function's docstring).
3. Minor: `hermes pm doctor` reports ffmpeg/ripgrep as "not installed" even when on PATH, because drift() only vouches for PM-managed installs — misleading with nix-managed ffmpeg. Cosmetic, confused the diagnosis here.

## If you actually DO need `hermes pm install` to work someday

Workaround exists (verified steps 1-2 only, did not run 3): copy `-hermes-python-source` to a writable dir, run the sync from the app interpreter with `pm.packages.Venv.project_root` and `pm.paths.repo_root` monkeypatched to that writable copy. It then proceeds further into generation creation and hits bug 2. Fix bug 2 by patching the writable copy's `pm/workspace.py` the same way. NOT recommended as a standing fix — it forks the declared environment and the gateway still boots from the nix venv. Prefer the upstream fixes + flake update.
