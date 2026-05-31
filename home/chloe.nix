{config, pkgs, inputs, ...}:

{
  imports = [
    
    # in nixos module, not home
    # ./xdg.nix
    ./stylix.nix
    ./home-programs.nix

    ### specific modules for some packages
    ./niri.nix
    ./eww.nix
    ./fish.nix
    ./yazi.nix
    ./neofetch.nix
    ./dunst.nix
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

