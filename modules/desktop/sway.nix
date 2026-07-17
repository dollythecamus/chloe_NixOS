{config, pkgs, lib, inputs, ...}:

{
  wayland.windowManager.sway = {
    enable = true;
  };

  environment.sessionVariables = {
	XDG_CURRENT_DESKTOP = "sway";
	XDG_SESSION_TYPE = "wayland";
  };

  environment.systemPackages = with pkgs; [
    swaybg
    wl-copy
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
