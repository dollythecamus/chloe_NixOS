{config, pkgs, inputs, ...}:

{
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    config.common.default = ["wlr" "gnome" "gtk"];
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ]; 
  };

  home.sessionVariables = {
    TERMINAL = "kitty";

    XDG_CURRENT_DESKTOP = "niri";
    WAYLAND_DISPLAY = "wayland-0";
    QT_QPA_PLATFORM = "wayland";

    WLR_DRM_NO_MODIFIERS=1;
    WLR_RENDERER="vulkan";
    # XDG_CURRENT_DESKTOP="sway";
    QT_QPA_PLATFORM="wayland";
    CLUTTER_BACKEND="wayland";
    SDL_VIDEODRIVER="wayland";
  };
}
