{pkgs, ...}:

{
  # cua-driver: the backend behind Hermes' `computer_use` toolset (see
  # pkgs/cua-driver.nix for why it is packaged rather than installer-installed).
  # The toolset itself is enabled per-surface in
  # modules/config/hermes/config.yaml (platform_toolsets.cli).
  nixpkgs.overlays = [
    (final: prev: {
      cua-driver = prev.callPackage ../pkgs/cua-driver.nix { };
    })
  ];

  environment.systemPackages = [ pkgs.cua-driver ];

  environment.sessionVariables = {
    # Without this the driver only sees the XWayland bridge, so Wayland-native
    # windows (kitty, Chrome) are invisible; with it, niri advertises the full
    # wlroots set (foreign-toplevel, screencopy, virtual-pointer). Verified with
    # `hermes computer-use doctor` + a 1920x1080 screencopy capture on niri.
    CUA_DRIVER_RS_ENABLE_WAYLAND = "1";
  };
}
