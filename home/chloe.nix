{config, pkgs, inputs, ...}:

{
  imports = [
    ./stylix.nix
    ./home-programs.nix
    ./niri.nix
    ./eww.nix
    ./neofetch.nix
    ./wofi.nix
    ./vscode.nix
    ./ironbar.nix
  ];

  programs.home-manager.enable = true;

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

