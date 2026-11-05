# ARCHITECTURE — NixOS host configuration

One host (`chloe-laptop`, RTX 3050 laptop, no iGPU), one flake, four full-system outputs.
NixOS pinned to `nixos-26.05`; Hermes Agent comes from its own flake input
(`github:NousResearch/hermes-agent`, currently `69c7d67`) with `nixpkgs.follows = nixpkgs-unstable`.
Blender is pinned to a third nixpkgs input on purpose (see the comment in `flake.nix`).

Operational rules and the exact commands: [AGENTS.md](AGENTS.md). State and next action:
[docs/PROJECT_LEDGER.md](docs/PROJECT_LEDGER.md).

## Outputs — the `desktop` specialArg

`flake.nix` builds every output with `mkSystem <desktop>`; `<desktop>` is passed to the NixOS
modules *and* to Home Manager (`extraSpecialArgs`), and it is the only thing that differs.

| Output | `desktop` | Session | Display manager |
|---|---|---|---|
| `chloe-laptop` | `gnome` | GNOME (Wayland) — **daily driver** | GDM |
| `chloe-laptop-niri` | `niri` | niri (Wayland) + GNOME shim for plumbing | ly |
| `chloe-laptop-plasma` | `plasma` | Plasma 6 (Wayland) | ly |
| `chloe-laptop-xfce` | `xfce` | XFCE (**X11**) — recovery/login for `computer_use` | ly |

Modules branching on `desktop`: `host_chloe-laptop.nix` (which desktop module and shim are
imported), `home/chloe.nix` and `home/home-programs.nix` (niri-era Wayland daemons on/off),
`modules/cua-driver.nix` and `modules/hermes.nix` (Wayland vs X11 environment for the driver).
A new value must be handled in all five.

## Hermes stack (the reason the GPU/X11 work exists)

| Piece | Where | Runs as |
|---|---|---|
| Messaging gateway + tools | `modules/hermes.nix` → `hermes-agent.service` (**native**, container mode off since 2026-10-27) | `chloe:hermes`, `HOME=/var/lib/hermes`, `HERMES_HOME=/var/lib/hermes/.hermes` |
| Agent config, SOUL/ETHOS, profiles | `modules/config/hermes/` → installed at activation, edited **here** only | — |
| Desktop app (Electron) | `home/desktop-gnome.nix` + `home/hermes-desktop-launcher.nix` | the desktop session |
| Dashboard (phone / remote gateway) | `modules/remote-access.nix` → `hermes-dashboard.service`, tailnet address only | `chloe:hermes` |
| `computer_use` backend | `modules/cua-driver.nix` (`CUA_DRIVER_CMD`, Wayland flag only off X11) | driver child of the unit |

`~/.hermes` is a symlink to `/var/lib/hermes/.hermes`, recreated by the `hermes-home-bridge`
activation script; a real directory at that path is moved aside, never merged. Profiles `code`,
`nixos`, `learn` live under `profiles/` in that same state directory.

## Directory map

| Path | What it owns |
|---|---|
| `flake.nix` | inputs, `mkSystem`, the four outputs |
| `host_chloe-laptop.nix` | boot, kernel, identity, the per-desktop module import |
| `host_chloe-laptop_hardware.nix` | generated hardware config (do not hand-edit) |
| `hardware/nvidia.nix` | driver, modesetting, power management, `prime` (offload **off**: one GPU) |
| `modules/desktop/` | one file per session (`gnome`, `gnome-shim`, `niri`, `plasma`, `xfce`) + `ly` |
| `modules/hermes.nix` | gateway unit, config/identity files, state permissions, container-mode gates, dashboard-independent env |
| `modules/config/hermes/` | `config.yaml` (single default profile), SOUL/ETHOS files |
| `modules/remote-access.nix` | Tailscale, key-only SSH, declarative Syncthing vaults, `hermes-dashboard` unit |
| `modules/cua-driver.nix` | `computer_use` driver package and its env, per desktop |
| `modules/network.nix`, `services.nix`, `programs.nix`, `system-packages.nix`, `llm.nix`, `nix-ld.nix`, `revision.nix` | networking, services (docker, pipewire, portals), system programs, packages, LLM tooling, nix-ld, flake revision in `configurationRevision` |
| `modules/users/chloe.nix` | the user, groups, linger |
| `home/` | Home Manager: `chloe.desktop.nix` → `chloe.nix` + `desktop-gnome.nix`, plus per-app files (niri, eww, ironbar, wofi, vscode, stylix, gaming, programs/, fish/, dotfiles/) |
| `pkgs/` | local derivations: `cua-driver`, `lightpanda`, `hermes-faster-whisper`, `termagotchi` |
| `secrets.nix` + `secrets/` | agenix wiring and encrypted secrets (never plaintext here) |
| `xdg.nix` | portal defaults shared by every session |
| `docs/` | plans, handoffs, runbooks, `PROJECT_LEDGER.md` |

## Invariants and the check that proves each

- Only one GPU: `for d in /sys/bus/pci/devices/*; do case "$(cat $d/class)" in 0x03*) echo $d;; esac; done`
  → one line, `0000:01:00.0`, `10de:25ec`, driver `nvidia`; `/dev/dri` holds only
  `card1`/`renderD128` (`lspci` is not installed on this host). So
  `hardware.nvidia.prime.offload.enable` must stay `false` —
  `nix eval .#nixosConfigurations.chloe-laptop-xfce.config.services.xserver.videoDrivers` → `["nvidia"]`.
- No automatic suspend: the firmware has no S3 and s2idle resume hangs. Logind is set to
  `HandleLidSwitch=lock` in `modules/services.nix`; GNOME's own idle suspend is refused in
  `home/desktop-gnome.nix`.
- Hermes config is declarative: editing `/var/lib/hermes/.hermes/config.yaml` is undone by the
  next switch — `grep -c 'hermesHomeFiles' modules/hermes.nix` and the block itself are the
  source of truth.
- The live system is a separate fact from the tree:
  `nix-store -q --deriver "$(readlink -f /run/current-system)"`.

## Not verified yet (as of 2026-10-30)

- **The XFCE output has never logged in successfully.** The first X11 session died 8 s past ly's
  greeter (broken PRIME `amdgpuBusId`, see `hardware/nvidia.nix`); the fix is committed but
  **not switched**.
- **`hermes-dashboard.service` has never started.** The unit, its auth-env file
  (`/var/lib/hermes/.hermes/dashboard-auth.env`, 0600) and its ExecStart evaluate, and the tailnet
  address matches `tailscale ip -4`; nothing has proven it binds and serves.
- **Syncthing pairing is declared, not done.** `settings.devices.phone` and the `mind`/`wiki`
  shares render into the init script's POST payloads, but live `config/folders` is still `[]`
  until the switch; the phone side (Syncthing-Fork started, share accepted) is still owed.
- **The `dayboard` plugin cannot load**: `requires_env: DAYBOARD_AGENT_TOKEN` is absent from
  `/var/lib/hermes/.hermes/.env`, so `plugins.enabled: [dayboard]` is declared ahead of its token.
- Container-mode removal's Phase 4 (sudo cleanup of `/var/lib/hermes/home` and the stopped
  container) is outstanding; nothing depends on it.
