{config, pkgs, inputs, ...}:

# Pi coding agent (pi.dev) — a minimal, extensible harness installed *alongside*
# hermes-agent, not as a replacement: hermes owns the gateway, memory, cron and
# delegation surfaces, pi is here for the case where the agent loop itself is
# the thing being authored (TypeScript extensions, RPC mode, the SDK).
#
# Package source: upstream's own flake. nixpkgs lags badly here — on 2026-11-08
# nixos-26.05 pinned 0.75.4 and the nixpkgs-unstable input 0.87.1, against
# upstream 1.5.0 — so the version comes from the `pi` input instead (see the
# flake input comment for why that input is a commit and not a release tag).
#
# Config: no Home-Manager module exists for pi (checked 2026-11-08: nothing in
# nixpkgs' nixos/modules, and upstream's nix/ carries only package.nix and
# model-catalog.json), so the agent directory is managed by hand here. The split
# matters:
#   * READ-ONLY inputs are safe to symlink from the store — pi only reads them,
#     and that is what the home.file entry below does.
#   * settings.json / auth.json / models.json / sessions / installed packages
#     are deliberately NOT managed: `pi install`, `/login` and `/settings` all
#     write into ~/.pi/agent, so a store symlink at those paths fails with a
#     read-only error and pi's own package management breaks. That is also why
#     Nix does not "complicate the npm package manager" here: the flake owns the
#     binary, ~/.pi/agent stays an ordinary writable directory.
#   * `pi update` cannot update a Nix installation; the flake input is the
#     update channel.
let
  pi = inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # pi has no permission system of its own: it runs every tool with the
  # launching user's rights and never asks. This wrapper puts the whole process
  # behind a mount namespace instead of an approval prompt — the working
  # directory and ~/.pi/agent are writable, the rest of $HOME does not exist
  # inside, and the network stays up because the provider API needs it
  # (`pi-sandbox --no-net` drops it).
  #
  # Deliberately NOT bound: ~/.ssh, ~/.config/gh, /run/agenix. A sandboxed pi
  # therefore cannot push or read secrets; add a bind here if that becomes the
  # blocker, rather than dropping the sandbox.
  # `--new-session` is omitted on purpose: it detaches the controlling terminal,
  # which breaks the interactive TUI's job control and resize handling.
  pi-sandbox = pkgs.writeShellScriptBin "pi-sandbox" ''
    set -euo pipefail

    net=()
    if [ "''${1:-}" = "--no-net" ]; then
      net=(--unshare-net)
      shift
    fi

    agent_dir="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
    workdir="$PWD"
    mkdir -p "$agent_dir"

    # Binding $HOME itself would hand the sandbox the whole home directory,
    # which is the opposite of the point.
    if [ "$workdir" = "$HOME" ]; then
      echo "pi-sandbox: refusing to run in \$HOME -- cd into the project first." >&2
      exit 1
    fi

    exec ${pkgs.bubblewrap}/bin/bwrap \
      --die-with-parent \
      --unshare-user-try --unshare-pid --unshare-uts --unshare-ipc --unshare-cgroup-try \
      "''${net[@]}" \
      --ro-bind /nix/store /nix/store \
      --ro-bind-try /run/current-system /run/current-system \
      --ro-bind /etc /etc \
      --dev /dev --proc /proc --tmpfs /tmp \
      --bind "$workdir" "$workdir" \
      --bind "$agent_dir" "$agent_dir" \
      --ro-bind-try "$HOME/.gitconfig" "$HOME/.gitconfig" \
      --ro-bind-try "$HOME/.config/git" "$HOME/.config/git" \
      --chdir "$workdir" \
      --setenv HOME "$HOME" \
      --setenv PI_SANDBOX 1 \
      -- ${pi}/bin/pi "$@"
  '';
in
{
  home.packages = [ pi pi-sandbox ];

  home.sessionVariables = {
    # The store is the update channel, so the pi.dev version check tells us
    # nothing; install/update telemetry is opted out for the same reason.
    PI_SKIP_VERSION_CHECK = "1";
    PI_TELEMETRY = "0";
  };

  # House rules for this repo, harness-neutral: what any agent working in
  # ~/nixos must know. Kept out of hermes' SOUL because it is a property of the
  # tree, not of one profile.
  home.file.".pi/agent/APPEND_SYSTEM.md".source = ./pi/APPEND_SYSTEM.md;
}
