{config, pkgs, pkgs-unstable, inputs, ...}:

{
  imports = [
       # gamedev
        ./programs/unity.nix
        ./programs/godot.nix
        ./programs/blender.nix
       # general
        ./terminal.nix

       # gaming
  	./gaming.nix
  ];

  programs.nixcord = {
    enable = true;
    vesktop.enable = true;
  };

  programs.obsidian = {
    enable = true;
    cli.enable = true;
  };

  home.packages = with pkgs; [
    home-manager # make home-manager available for use in the terminal
    
    # rice
    wofi
    nvtopPackages.nvidia
    playerctl
    brightnessctl
    grim
    slurp
    glow
    pkgs-unstable.btop-cuda
    nvtopPackages.nvidia
    neocities
    vlc
    wl-clipboard
    nautilus
    peaclock
    starship # customizeable prompts for any shell
    bacon # rust compiler
    cargo-info # get data about rust packages from the internet without going through the browser
    rusty-man # rust docs in cli
    mask # command runner in a markdown file, woa
    presenterm # terminal slides presentation tool
    kew # music player

        # torrent
        qbittorrent

        # browser, office
        librewolf
	libreoffice 
      
        # art
        krita
        gimp 

        # music
        lmms

        # dev
        github-desktop
  ];

}
