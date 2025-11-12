{config, pkgs, inputs, ...}:

{
  imports = [
    ./hyprland.nix
    ./eww.nix
    ./fish.nix
    ./yazi.nix
    ./neofetch.nix
    ./wpaperd.nix
    ./dunst.nix
    ./wofi.nix
  ];
  
  stylix = {

    enable = true;
    autoEnable = true;
    
    # honestly dunno why i have to enable each one individually since autoEnable is true but whatevs;
    targets = {
    	hyprland.enable = true;
	fish.enable = true;
	kitty.enable = true;
	wofi.enable = true;
    	waybar.enable = true;
	neovim.enable = true;
	nixcord.enable = true;
	blender.enable = true;
	dunst.enable = true;
	vscode.enable = true;
	firefox.enable = true;
	bat.enable = true;
	yazi.enable = true;
	wpaperd.enable = true;
    };

    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyodark-terminal.yaml";

    cursor = {
      package = pkgs.simp1e-cursors;
      name = "Simp1e-Nord-Dark";
      size = 15;
    };

    fonts = {
      serif = config.stylix.fonts.monospace;
      sansSerif = config.stylix.fonts.monospace;
      emoji = config.stylix.fonts.monospace;
    };

    # image = ./wallpaper/puffy-stars.jpg;

    polarity = "dark";
  };

  # not good, but it's fine
  # rebuild is screaming at me to remove this
  # nixpkgs.config.allowUnfree = true;

  
  programs.nixcord = {
    enable = true;          # Enable Nixcord (It also installs Discord)
    vesktop.enable = true;  # Vesktop
    #dorion.enable = true;   # Dorion
  };

  programs.vscode.enable = true;

  # neovim waow
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;

  programs.kitty.enable = true;
  programs.home-manager.enable = true;

  home = {
    stateVersion = "25.05";
    username = "chloe";
    homeDirectory = "/home/chloe";
    packages = with pkgs; [
     
      # # # rice # # # 

	terminaltexteffects # cool

        # home-manager

        # kitty
        fish
        # dunst
        wofi
        # wpaperd 

        base16-schemes

        playerctl
        brightnessctl

        grim
        slurp

        glow

        neofetch
        neocities
        #neovim

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
    #wiki-tui # wikipedia in cli! how queer!
    mask # command runner in a markdown file, woa
    presenterm # terminal slides presentation tool
    #ncspot # spotify but good

	kew # music player

	 ## bullcrap end

      # Gaming             
        prismlauncher
        ckan
        lutris
        wine

      # Mic
        # nixcord
        qbittorrent
        drawpile 

      # Productivity
        obsidian
        librewolf
	libreoffice 
      
      # Creation
        krita
        godot # 4.4
        # unstable_nixpkgs.pkgs.godot # 4.5
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
      	#vscode
        github-desktop
      ];
  };
}

