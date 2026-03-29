{ pkgs, ... }:

{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
    settings = {
      # Nvidia-specific optimizations
      environment = {
        "DISPLAY" = ":0";
        "GBM_BACKEND" = "nvidia-drm";
        "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
        "LIBVA_DRIVER_NAME" = "nvidia";
      };

      input = {
        touchpad = {
          tap = true;
          dwt = true;
        };
      };

      layout = {
        gaps = 8;
        center-focused-column = true;
        default-column-width = { proportion = 0.5; };
      };

      binds = with config.lib.niri.actions; {
        "Mod+Return".action = spawn "kitty fish"; # terminal
        "Mod+S".action = spawn "woffi --show drun"; # app launcher
        
        "Mod+C".action = close-window;
      };
    };
  };
}