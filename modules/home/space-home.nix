{config, pkgs, inputs, ...}:

{
  
  home = {
    username = "chloe-inventor:";
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

  # themed everything, easy
  stylix = {
    autoEnable = true;
    enable = true;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/black-metal-mayhem.yaml";

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

    image = ./wallpaper/puffy-stars.jpg;

    polarity = "dark";
  };

  environment.systemPackages = with pkgs; [

    kitty
    fish
    waybar
   
    killall

    base16-schemes
  ];

  # login manager
  services.displayManager.ly = {
    enable = true;
    # can configure more :3
  };
  # Enable Hyprland
  programs.hyprland.enable = true;

  # Enable Electron apps for wayland
  # environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,br";
    variant = "";
  };

}
