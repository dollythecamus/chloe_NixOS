{config, pkgs, inputs, ...}:

{
  stylix = {

    enable = true;
    autoEnable = true;
    
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

  environment.systemPackages = with pkgs; [

    grim 
    slurp

    kitty
    fish
    dunst
    wofi
    swww
   
    killall

    base16-schemes
 
    playerctl
    brightnessctl

  ];

  # login manager
  services.displayManager.ly = {
    enable = true;
    # can configure more :3
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,br";
    variant = "";
  };

}
