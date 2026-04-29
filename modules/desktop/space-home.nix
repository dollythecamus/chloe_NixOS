{config, pkgs, inputs, ...}:

{
  
  # does it conflict with the ly dm? idunno
  # what i know is that many programs won't work reliably without gnome as DE
  # and i want the reliability
  # until i can solve the problems relating to authentication and other things
  # this will have to do

  # services.xserver.displayManager.gdm.enable = true;
  # replace with actually configured system instead of using GNOME to patchwork
  services.desktopManager.gnome.enable = true;

  # programs.hyprland.enable = true; # niri was better :3

  # login manager
  services.displayManager.ly = {
    enable = true;
    
    settings = {
      clock = "%c";
      bigclock = true;
      animate = true;
      animation = "matrix";
    };
    # can configure more :3
    # ly is pretty >~<
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,br";
    variant = "";
  };

  environment.pathsToLink = [
    "/share/xdg-desktop-portal" "/share/applications"
  ];

}
