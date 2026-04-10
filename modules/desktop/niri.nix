{ pkgs, inputs, config, lib, ... }:

{
  programs.niri = {
    enable = true;
  };
 
  
  environment.sessionVariables = {
	XDG_CURRENT_DESKTOP = "niri";
	XDG_SESSION_TYPE = "wayland";
  };

  # niri doesn't run X11 applications by default, so it needs Xwayland
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    xwayland
  ];

}
