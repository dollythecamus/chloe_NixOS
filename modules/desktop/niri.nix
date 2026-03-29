{ pkgs, inputs, config, lib, ... }:

{
  programs.niri = {
    enable = true;
  };
  
  # niri doesn't run X11 applications by default, so it needs Xwayland
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    xwayland
  ];

}
