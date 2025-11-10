{config, pkgs, inputs, ...}:

{
  
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
