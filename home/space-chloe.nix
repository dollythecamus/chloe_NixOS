{config, pkgs, inputs, ...}:

{
  imports = [
    ./hyprland.nix
    ./eww.nix
    #./fish.nix
  ];
  
  stylix = {

    enable = true;
    autoEnable = true;
    
    targets = {
    	hyprland.enable = true;
	fish.enable = true;
	kitty.enable = true;
	wofi.enable = true;
    	waybar.enable = true;
	neovim.enable = true;
    };

    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyodark-terminal.yaml";

    cursor = {
      package = pkgs.simp1e-cursors;
      name = "Simp1e-Nord-Dark";
      size = 15;
    };

    fonts = {
      # serif = config.stylix.fonts.monospace;
      # sansSerif = config.stylix.fonts.monospace;
      # emoji = config.stylix.fonts.monospace;
    };

    #image = ./wallpaper/puffy-stars.jpg;

    polarity = "dark";
  };

  # not good, but it's fine
  nixpkgs.config.allowUnfree = true;

  # ...
  programs.kitty.enable = true;
  programs.home-manager.enable = true;

  home = {
    stateVersion = "25.05";
    username = "chloe";
    homeDirectory = "/home/chloe";
    packages = with pkgs; [
     
      # # # rice # # # 

        home-manager

        kitty
        fish
        dunst
        wofi
        swww

        base16-schemes

        playerctl
        brightnessctl

        grim
        slurp

        glow

        neofetch
        neocities
        neovim

        vlc
        wl-clipboard

        adwaita-icon-theme
        font-awesome 

      #   rice over  #

	 # rust bullcrap
	
    uutils-coreutils # GNU coreutils
    fish # command line shell
    fd # alternative to find
    bat # cat, but better (idk what cat is
    eza # alternative to ls
    zoxide # smarter cd
    zellij # interesting ui
    gitui # git ui 
    dust # pretty disk analyzer
    starship # customizeable prompts for any shell
    yazi # interesting file manager
    bacon # rust compiler
    cargo-info # get data about rust packages from the internet without going through the browser
    rusty-man # rust docs in cli
    wiki-tui # wikipedia in cli! how queer!
    mask # command runner in a markdown file, woa
    presenterm # terminal slides presentation tool 

	 ## bullcrap end

      # Gaming             
        prismlauncher
        ckan
        lutris
        wine

      # Mic
        discord
        qbittorrent
        drawpile 

      # Productivity
        obsidian
        librewolf
	libreoffice 
      
      # Creation
        krita
        godot # 4.4
        # inputs.unstable_nixpkgs.pkgs.godot # 4.5
        #unstable.godot-mono

        libresprite
        blender
        audacity
        lmms
        freecad
        inkscape 
        gimp 
        gmic-qt
        gmic
        pureref

      # Development
      	vscode
        github-desktop
      ];
  };
}

