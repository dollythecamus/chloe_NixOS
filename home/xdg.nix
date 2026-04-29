{config, pkgs, inputs, ...}:

{
  xdg.portal = {
    enable = true;
    xdg.portal.config.common.default = "";
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ]; 
  };

  home.sessionVariables = {
    TERMINAL = "kitty";
    XDG_CURRENT_DESKTOP = "niri";
  };
}
