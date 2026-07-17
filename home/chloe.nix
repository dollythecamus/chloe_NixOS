{config, pkgs, inputs, ...}:

{
  imports = [
    ./sway.nix
    ./stylix.nix
    ./home-programs.nix

    ### specific modules for some packages
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
  };
}

