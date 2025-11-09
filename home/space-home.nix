{config, pkgs, inputs, ...}:

{
    imports = [
	./hyprland.nix
    ];
    
    stylix = {

    targets = {
	fish.enable = true;
	kitty.enable = true;
	wofi.enable = true;
    };
    
    autoEnable = true;
    enable = true;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/black-metal-mayhem.yaml";

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

    image = ./wallpaper/puffy-stars.jpg;

    polarity = "dark";
    
    };

  # ...
  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;

  home = {
    stateVersion = "25.05";
    username = "chloe-inventor";
    homeDirectory = "/home/chloe-inventor";
    packages = with pkgs; [
      
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
