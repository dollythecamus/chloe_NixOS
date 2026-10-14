{config, pkgs, inputs, desktop, ...}:

{
  imports = [
    ./stylix.nix
    ./home-programs.nix

    ./wofi.nix
    ./vscode.nix
  ] ++ (if desktop == "gnome"
        then [ ] # GNOME session owns the desktop: no niri/eww/ironbar rice.
        else [ ./niri.nix ./eww.nix ./ironbar.nix ]);

  programs.home-manager.enable = true;

  # GitHub accepts the registered GitHub key, not the default id_ed25519 identity.
  # Keep this user-specific client mapping in Home Manager, not secrets.nix:
  # it selects an SSH client identity and contains no secret material.
  programs.ssh = {
    enable = true;
    # Keep the generated config limited to explicit host mappings; the HM default
    # Host * block is deprecated and adds unrelated client-wide behavior.
    enableDefaultConfig = false;
    matchBlocks."github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519_github";
      identitiesOnly = true;
    };
  };

  home = {
    stateVersion = "26.05";
    username = "chloe";
    homeDirectory = "/home/chloe";

    # `hermes profile alias` writes its wrapper scripts here (e.g. `hcode` for
    # the `code` profile). Home Manager does not put this directory on PATH by
    # default, so without this the alias exists on disk but is unreachable —
    # verified 2026-09-21: the script was created and `hcode` was not found.
    sessionPath = [ "$HOME/.local/bin" ];
  };
}

