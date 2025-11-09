{config, pkgs, lib, inputs, ...}:

{
  

  environment.systemPackages = with pkgs; [

    kitty
    fish
    waybar
   
    killall
  ];

  # login manager
  services.displayManager.ly = {
    enable = true;
    # can configure more :3
  };

  # themed everything, easy
  stylix = {
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
