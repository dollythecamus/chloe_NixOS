{config, pkgs, inputs, ...}:

{
  stylix = {
    enable = true;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/solarized-dark.yaml";

    targets = {
    	grub.enable = false;
    };

  };
  
  # does it conflict with the ly dm? idunno
  # what i know is that many programs won't work reliably without gnome as DE
  # and i want the reliability
  # until i can solve the problems relating to authentication and other things
  # this will have to do
  
  # yes it conflicts, disable it works?
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  programs.hyprland.enable = true;

  # login manager
  # one time thing, to play games in X11 better
  /*
  services.displayManager.ly = {
    enable = true;
    
    settings = {
      clock = "%c";
      bigclock = true;
      animate = true;
      animation = "matrix";
    };
    # can configure more :3
  };
  */


  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,br";
    variant = "";
  };

}
