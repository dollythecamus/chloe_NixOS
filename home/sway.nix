{config, pkgs, lib, inputs, ...}:

{
  wayland.windowManager.sway = {
    enable = true;
  };

  home.sessionVariables = {
	XDG_CURRENT_DESKTOP = "sway";
	XDG_SESSION_TYPE = "wayland";
  };

  home.packages = with pkgs; [
   
    swaybg
    wl-clipboard
    mako
    pipewire
    xwayland-satellite
    xwayland
  ];

  programs.swaylock = {
    enable = true;
  };

  services.swayidle = {
    enable = true;
  };
}
