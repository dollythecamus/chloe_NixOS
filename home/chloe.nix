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
    ./hermes.nix
  ];

  programs.home-manager.enable = true;

  home = {
    stateVersion = "26.05";
    username = "chloe";
    homeDirectory = "/home/chloe";
  };
}

