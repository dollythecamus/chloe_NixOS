{config, pkgs, inputs, ...}:

{
  stylix = {
    enable = true;
    autoEnable = true;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/solarized-dark.yaml";

  };
  
  programs.hyprland.enable = true;

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
