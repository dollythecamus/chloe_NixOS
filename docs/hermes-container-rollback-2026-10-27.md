# Reversing the Hermes OCI container (2026-10-27)

Requested by Chloe: "the container sometimes limits capabilities — what are the real
pros and cons, and prepare a plan for reversing it."

Everything below was measured **from inside the running container** (2026-10-27, session
running as uid 1000 / `ubuntu`) or read from the module source that produced it
(`~/nixos/modules/hermes.nix` + `nixosModules.nix` from the `hermes-agent` flake input).
Nothing was changed to produce this document.

---

## 1. What container mode actually changes

`services.hermes-agent.container.enable = true` swaps one systemd service for one
`docker create`. The differences that matter:

| | native (mode A) | container (mode B) |
|---|---|---|
| process | `hermes gateway run` as unit `hermes-agent` | `docker start -a` → entrypoint → `setpriv --reuid=1000` → gateway |
| HOME | `/var/lib/hermes` | `/home/hermes` (= `/var/lib/hermes/home`) |
| HERMES_HOME | `/var/lib/hermes/.hermes` | `/data/.hermes` (= same directory) |
| filesystem | whole host, `ProtectSystem=strict`, `ProtectHome=false` | `/nix/store:ro`, `/var/lib/hermes`, `/home/chloe:rw`, `/run/current-system:ro`, `/etc/static:ro`, `/etc/hermes:ro` |
| privileges | chloe, no root | chloe + `sudo` NOPASSWD (root **inside the container only**) |
| writable OS | none (nix store is read-only) | apt/pip/npm layer, persists across restarts |
| systemd | full unit, `linger` default **true** | no systemd, no user manager, `linger` default **false** |
| devices | all host devices | container default set only |
| network | host | `--network=host` (no NAT) |
| CLI path | `hermes` runs locally | `hermes` → `.container-mode` → `docker exec -u 1000` |

---

## 2. Real pros (all verified this session)

1. **A writable OS layer.** `apt-get install -s` resolves and would install; `sudo -n true`
   succeeds; the entrypoint provisioned Node 22 (NodeSource), `uv`, and a seeded
   `~/.venv` (python 3.12 + pip). Natively every new CLI tool is a flake edit plus a
   rebuild, or a `nix-shell` that dies with the session.
2. **A real root that is not the host root.** Root inside the container can `apt`, edit
   `/etc`, install services — and cannot touch `/nix/store`, host units, or
   `/var/lib/hermes` outside the bind mounts. That containment is genuine.
3. **Self-modification is expendable.** `docker rm -f hermes-agent` returns a clean layer;
   the `mkBefore` preStart guard auto-discards a half-provisioned layer (the dpkg brick of
   2026-10-24). No repair script, no store corruption.
4. **The chloe/hermes dual-owner lockout stays fixed.** Gateway and CLI are both uid 1000,
   so the 0600-vs-group-chmod fight (`hermes-repair-perms`) cannot recur by construction.
5. **`--network=host`.** Tailscale IP, `localhost` services (lmstudio, obs-websocket) and
   Discord all reachable with zero port mapping.
6. **State is untouched by container lifecycle.** Sessions, skills, memory live in
   `/var/lib/hermes`, mounted at `/data`; container recreation loses nothing.

## 3. Real cons (each one measured; these are the "limits capabilities")

1. **No host control plane.** `systemctl`, `loginctl`, `systemd-run` are **not present**
   (`command -v` → MISSING inside the container). The agent cannot inspect, restart or
   repair the gateway unit, timers, or any host service it is responsible for.
2. **No user session, no bus, no audio.** `/run/user` does not exist in the container at
   all. Consequences, concrete:
   - `computer_use` can only answer "driver unavailable" — it needs
     `/run/user/1000/bus` + the WinRects GNOME helper. (Native mode is also crippled on
     this host, driver 0.28.1 owner-proof failure, but native keeps portal screenshots;
     the container removes the last of it.)
   - No session D-Bus → no notifications, no keyring, no portals.
   - No PipeWire/Pulse socket → the agent cannot listen to or route audio (TTS works
     because it writes a file; anything that evaluates *what reaches the stream* cannot
     be tested from a tool call).
3. **No devices.** `/dev` holds only `null zero full random urandom tty ptmx pts shm
   mqueue core fd`. Missing: `/dev/nvidia*`, `/dev/dri`, `/dev/snd`, `/dev/kvm`. So no
   GPU CUDA work from the agent (blender render, whisper on GPU, `ffmpeg` nvenc,
   btop-cuda, lmstudio GPU), no audio capture, no nested VM. The host has the nvidia
   module; the container simply never sees it.
4. **nix is crippled.** `/nix/store` is ro and `/nix/var/nix` does not exist; `nix` is not
   on PATH; plain evaluation fails with
   `creating directory "/nix/var/nix/profiles": Permission denied`. The workaround works
   but is expensive and partial: `--store ~/.local/share/nix/root` needs a chroot root
   inside her home and took **58 s** for one whole-system eval, and "which output is
   live" is unanswerable because `/run/current-system` here is a bind mount, not a
   symlink into the store. `nixos-rebuild build` (the no-sudo pre-build) cannot run at
   all.
5. **The self-modification pro is half-hollow for the agent's own runtime.** The gateway
   runs the sealed nix python 3.14, and `PYTHONPATH` is pre-seeded with store
   site-packages (numpy, faster-whisper, av, ctranslate2…). `pip3` on PATH is
   `/home/ubuntu/.venv/bin/pip3`, python **3.12**, a different interpreter. So
   `pip install foo` succeeds and `python3 -c "import foo"` still fails — two python
   worlds. A dependency the agent itself needs still requires the flake
   (`extraPythonPackages`), i.e. the native process.
6. **Identity drift.** Container `passwd` has `root` and `ubuntu` (uid 1000) only — no
   `chloe`, no `hermes`. `HOME=/home/hermes`, `HERMES_HOME=/data/.hermes`, real home
   `/home/chloe`. Three home trees and two state paths mean writes land in the wrong
   place and "file not found" is routine; upstream needed `exec_user=1000` plus a
   bash-builtins-only activation hook because `docker exec -u chloe` fails.
7. **Bind mounts pinned to a target generation.** `/run/current-system` and `/etc/static`
   are re-resolved only on `docker start`. A `nix-collect-garbage -d` that removes the
   generation the container booted on breaks piper (TTS) and `npx` (godot MCP) until
   `systemctl restart hermes-agent`. Natively a switch re-points both for free.
8. **Crash semantics.** Gateway is PID 1 under tini; `docker stop` kills every tool
   subprocess and cron worker mid-flight; no long job survives a restart. First-boot apt
   provisioning is a ~5 min window with its own guard because interrupting it bricks the
   layer.
9. **Ownership debris in shared state.** `find /var/lib/hermes ! -user chloe` = **5,920
   files**: 5,909 under `/var/lib/hermes/home` owned `994:993`, plus root-owned
   `.container-identity`, `current-package`, `current-entrypoint`, `.gc-root*`, `.npm`,
   `.config`, `.cua-driver`, `vtube`. Harmless while the container pins uid 1000; a
   reversal hazard (see Phase 2).
10. **"Real root" stops at the container wall.** Anything needing host privilege —
    permissions on `/var/lib/hermes`, system units, nix profile — is still Chloe's sudo.
    So the agent gains root where it did not need it and keeps none where it does.

### Verdict

The container buys exactly one thing: install-a-tool-now without a rebuild. It pays for
it with no systemd, no bus, no devices, a crippled nix, and an identity/path split. Given
that (a) the *reported* breakage is capability loss, (b) the writable python does not
extend the agent's own interpreter, and (c) the permission lockout it was partly meant to
prevent was already solved by single-owner state, the trade has stopped paying. Reversal
is the smaller configuration.

---

## 4. Reversal plan

Order matters. Phase 1 is the only file edit; Phase 3 is Chloe's switch.

### Phase 0 — decided 2026-10-27: option (a), `workingDirectory = "/home/chloe"`

Live output confirmed by Chloe: **`chloe-laptop`** only. Phase 1 was applied the same day;
the evaluated evidence is under Phase 2.

### Phase 0 (original note) — decide one thing (no writes)

Native mode sets `WorkingDirectory` to the module default
`/var/lib/hermes/workspace`. The container overrides it with `--workdir /home/chloe`, so
sessions currently start in `/home/chloe`. Choose:

- **(a) keep current behaviour** → add `workingDirectory = "/home/chloe";` to
  `services.hermes-agent` (recommended: no surprise change in where terminal/project
  context starts), or
- **(b) accept `/var/lib/hermes/workspace`** → no edit, note the behaviour change.

### Phase 1 — DONE 2026-10-27 (`~/nixos/modules/hermes.nix`, one file, four hunks)

1. **Flip the switch.**
   `container.enable = true;` → `false;`. Keep the rest of the `container = { … }` block
   (image, hostUsers, extraVolumes, extraOptions) untouched: it is only read when
   `enable` is true, and keeping it makes rollback a one-word edit. Replace the
   2026-10-24 rationale comment with a 2026-10-27 note saying *why* it was turned off
   (capability list above, condensed) and that the block is retained for rollback.
2. **Gate `systemd.services.hermes-agent.preStart`** (the docker dpkg-brick guard) on
   `config.services.hermes-agent.container.enable`. Natively it injects three `docker`
   calls into the native unit and would `docker rm -f hermes-agent` on every start.
   Upstream's own native `preStart` (the linger/user-bus wait) then applies unchanged.
3. **Gate activation script `hermes-container-cleanup`** on `container.enable`. This one
   is a live bug on reversal: with the container stopped, the hook's test is false, so it
   `rm -f`s `gateway.sock`/`.pid`/`.lock`. On any later switch that does not itself
   restart the native unit, that unlinks the socket of a **running** gateway and
   Desktop/CLI fail with ENOENT until it restarts.
4. **Gate activation script `hermes-container-exec-user`** on `container.enable` (it is
   already a no-op once `.container-mode` is gone, but the hook should not exist in a
   configuration that has no `.container-mode`).

Leave as-is, they are native-correct already:

- `systemd.services.hermes-agent.environment` (the `computer_use` Wayland/D-Bus block) —
  it becomes effective again; its comment already says "native mode only".
- `hermesHomeFiles`, `user = "chloe"`, `createUser = false`, `addToSystemPackages = true`
  (natively this just puts `hermes` on the unit/system PATH).
- `environment.etc."hermes/piper"` + the `config.yaml` absolute paths
  (`/run/current-system/sw/bin/piper`, `/etc/hermes/piper`, `npx`, `GODOT_MCP_PROJECT_PATH`)
  — all native paths, no `config.yaml` change needed.
- `linger` flips itself: the module sets `linger = mkDefault (!container.enable)`, so the
  user manager (and restart-safe cron) come back with the switch.

### Phase 2 — verify by evaluation, before she switches

```bash
cd /home/chloe/nixos
export XDG_CACHE_HOME=$TMPDIR/nixcache; mkdir -p $XDG_CACHE_HOME
N="/nix/store/9jszq1xqwzx9svddksz4qm34wisgxyma-nix-2.34.8/bin/nix \
   --extra-experimental-features nix-command --extra-experimental-features flakes \
   --store /home/chloe/.local/share/nix/root"
# baseline captured 2026-10-27 before the edit:
#   /nix/store/j30c9907dvcpl2rqm24p0nc9y8jf7az3-nixos-system-chloe-laptop-26.05.20260719.fd14620.drv
$N eval --raw .#nixosConfigurations.chloe-laptop.config.system.build.toplevel.drvPath
```

- The drv **must differ** from the baseline above; identical means the edit did not land.
  **Applied 2026-10-27:** baseline `j30c9907…fd14620.drv` → after the edit
  `csdpcycwba23hqnqh93sf3cn0jijz0z6-nixos-system-chloe-laptop-26.05.20260719.fd14620.drv`.
  Same evaluation returned: `container=false`, `workingDirectory=/home/chloe`,
  `linger=true`, `unitUser=chloe`, `ExecStart=/nix/store/k0r2…-hermes-agent-0.0.0/bin/hermes
  gateway`, `preStart` = upstream's linger/user-bus wait (no docker), and
  `activationScripts` = only `hermes-agent-setup` + `hermes-home-mode` — the three
  container hooks are gone from the evaluated config, not merely skipped at runtime.
- Then read back the three gated values and `users.users.chloe.linger` (`true`).
- Whole-system eval must succeed for the output she actually boots. She is the only one
  who can say which one is live — the container cannot see `/run/current-system`'s
  target. Hand over all three rebuild commands if unsure.
- `git add modules/hermes.nix` is unnecessary (tracked, edited in place), but the tree
  must not be left with an untracked new module.

### Phase 3 — VERIFIED LIVE 2026-10-27 17:59:43 (Chloe switched at 17:59:42)

The switch built exactly the predicted closure: `nix-store -q --deriver
$(readlink -f /run/current-system)` = `csdpcycwba23hqnqh93sf3cn0jijz0z6-nixos-system-chloe-laptop-26.05.20260719.fd14620.drv`,
the same drv Phase 2 predicted, and the live generation is
`/nix/store/1qfdd6wgvqq4aj50as3id5x5642vwija-nixos-system-chloe-laptop-26.05.20260719.fd14620`.

Measured after the switch, in the runbook's order:

| check | result |
|---|---|
| `systemctl status hermes-agent` | `active (running)`, `ExecStart=…/hermes-agent-0.0.0/bin/hermes gateway`, `User=chloe`, `Group=hermes`, `NRestarts=0`, `ExecStartPre` (lingering/user-bus wait) exited 0 |
| `$HERMES_HOME/.container-mode` | absent |
| `docker ps -a` | `hermes-agent  Exited (1) 28 minutes ago  ubuntu:24.04` — stopped, layer kept |
| `loginctl show-user chloe -p Linger` | `Linger=yes`; `/run/user/1000/bus` present |
| `hermes` | resolves to `/run/current-system/sw/bin/hermes`, runs **locally** (no `docker exec`) |
| `nix eval …toplevel.drvPath` (no `--store`) | works, 30 s — needs a writable `XDG_CACHE_HOME`, which is the documented non-container quirk (`~/.cache/nix` under the state dir is root-owned), not a mode artifact |
| godot MCP | running natively (`node /var/lib/hermes/.npm/_npx/…/godot-mcp-server`); npx re-resolved into the native `HOME` |
| TTS | the exact `config.yaml` piper command produced a 62 KB wav |
| GPU | `nvidia-smi` → RTX 3050 Laptop, driver 595.71.05 |
| audio | `pipewire`/`pipewire-pulse` active, socket `/run/pulse/native` (this host runs pipewire `systemWide`, so there is no `/run/user/1000/pipewire-0`) |
| devices | `/dev/nvidia0`, `/dev/dri`, `/dev/snd`, `/dev/kvm` all present |
| Discord | one transient `Temporary failure in name resolution` at 18:04–18:05 (boot network race, resolved by 18:06); messages delivered afterwards |

**Ownership audit corrected.** In-container the count was 5,920 because the container's
uid 1000 was *not* in group `hermes` and `find` silently failed to descend into the
`2770 994:hermes` directories (`home/.local` alone hides 4,746 files). Correct number from
the host: **10,402 files owned `994:hermes` + 5 root-owned**, concentrated in
`home/.local` (4,746), `.config/opencode` (3,929), `home/.venv` (579), `home/.cache` (573),
`.npm/_cacache` (402). Practical impact: **zero** — `find … \( -perm -u=rw -a ! -perm -g=r \)`
returns **0** owner-only foreign files, so every one of them is group-readable/writable to
Chloe through `hermes`. It is cosmetic debt, and Phase 4 fixes it.

### Phase 3 (original checklist) — she switches

```bash
sudo nixos-rebuild switch --flake /home/chloe/nixos#chloe-laptop
```

Then, in this order:

1. `systemctl status hermes-agent` → native unit, `Active: active (running)`,
   `ExecStart=…/hermes gateway run`.
2. `systemctl show hermes-agent -p NRestarts` / `journalctl -u hermes-agent -b -n 50` →
   no `docker` invocations, no socket errors.
3. `ls -l /var/lib/hermes/.hermes/.container-mode` → **must not exist** (upstream
   activation removes it). If it survives, the host CLI will try `docker exec`.
4. `docker ps -a --format '{{.Names}}\t{{.Status}}'` → `hermes-agent` stopped (docker
   itself stays enabled via `modules/services.nix`, so the layer stays on disk for
   rollback).
5. `loginctl show-user chloe -p Linger` → `Linger=yes`; `ls -l /run/user/1000/bus` exists.
6. A fresh turn from Discord: `hermes` reply arrives (gateway healthy, provider keys
   loaded from the agenix env file).
7. `hermes config get model.default` on the host → runs **locally**, no `docker exec`.
8. TTS round trip (piper via absolute path) — the container's bind-mount fragility for
   `/etc/hermes` no longer applies.
9. `nix eval .#nixosConfigurations.chloe-laptop.config.system.build.toplevel.drvPath`
   **without** `--store` → works again (nix daemon reachable).
10. godot MCP: `/home/chloe/projects/magical-collector` opens; first launch re-downloads
    `npx` cache into the native HOME.
11. `computer_use` — expect **no improvement** over today (GNOME adapter refuses on
    driver 0.28.1 / owner-proof); the point is that the bus and portals exist again.
12. GPU/audio reachability: `nvidia-smi`, `ls /dev/snd` from a tool call.

### Phase 4 — host cleanup (her sudo). STILL OUTSTANDING as of 2026-10-27 18:30

Phase 3 passed, so the commands below are safe to run. Nothing in Phase 4 is required for
the system to work — it removes the stopped container, the container-era home, and the
cosmetic ownership debt.

1. Remove the container and its artifacts:
   `sudo docker rm -f hermes-agent`
   `sudo rm -f /var/lib/hermes/.container-identity /var/lib/hermes/current-package
   /var/lib/hermes/current-entrypoint /var/lib/hermes/.gc-root
   /var/lib/hermes/.gc-root-entrypoint`
   (the `.gc-root*` symlinks are what keep the old package alive against GC).
2. Archive `/var/lib/hermes/home` (215 MB, last real content Sep 7, uid 994; natively
   nothing reads it — native `HOME` is `/var/lib/hermes`):
   `sudo tar czf /home/chloe/hermes-container-home-2026-10-27.tar.gz -C /var/lib/hermes home`
   then `sudo rm -rf /var/lib/hermes/home` once she is happy with the switch.
3. Chown the container-era leftovers that native mode *does* read:
   `sudo chown -R chloe:hermes /var/lib/hermes/.cua-driver /var/lib/hermes/.config
   /var/lib/hermes/.npm /var/lib/hermes/vtube`
4. Whole-tree audit: `find /var/lib/hermes ! -user chloe ! -group hermes` must return
   nothing that the gateway needs to write.
5. Nothing was installed with apt after first-boot provisioning
   (`/var/log/dpkg.log` last written 2026-10-24 22:35; `dpkg --audit` clean), so the apt
   layer holds nothing worth exporting. The python venv at
   `/home/hermes/.venv` exists only in that layer and is not used by the gateway
   interpreter — discard with the archive.

### Phase 5 — rollback (if the reversal is wrong)

`container.enable = true;` + switch. If the container was already removed, the preStart
recreates it from `ubuntu:24.04` and re-provisions apt/node/uv (≈5 min, needs network);
state in `/var/lib/hermes` is untouched throughout. Keep `docs/` + git history as the
record of why it was on, why it went off, and what it cost.

---

## 5. Decisions (2026-10-27)

1. **Live output:** `chloe-laptop` only — the other two outputs were not built for this
   change and are irrelevant to it.
2. **Working directory:** `/home/chloe`, declared explicitly (Phase 0 option a).
3. **Commit:** offered as its own commit with the message below; the file is edited and
   verified but **nothing is staged or committed yet**, and `home/home-programs.nix` is
   still dirty from an earlier change that is not part of this one.
4. **Phase 3 (the switch) is Chloe's** — it has not run. Until it does, the container
   deployment is still live and this document describes a planned state, not a live one.


Draft commit message:

```
hermes: run the gateway natively again (container off)

The OCI container bought a writable apt/pip/npm layer and cost the host
control plane: no systemctl/loginctl, no /run/user session, no D-Bus,
no /dev/nvidia|dri|snd|kvm, no nix daemon (58 s chrooted eval, "which
output is live" unanswerable) and a split identity (ubuntu/HOME
/home/hermes/HERMES_HOME /data/.hermes). The writable python also never
reaches the gateway interpreter (pip3 = 3.12, gateway = sealed 3.14
with store PYTHONPATH). Single-owner state already fixes the permission
lockout the container was partly for, so the trade no longer pays.

container.enable = false; the block is kept for a one-word rollback.
The two container activation hooks and the docker preStart guard are
now gated on container.enable — ungated, hermes-container-cleanup would
unlink a running gateway's socket on any switch that does not restart
the unit.
```
