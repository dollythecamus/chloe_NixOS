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
    # The desktop app's backend (`hermes serve`) is spawned from the GNOME
    # session, not from the systemd gateway unit, so it does not inherit the
    # unit's environment. The computer_use resolver only honours this variable
    # (or a pm-installed driver); without it the desktop backend reports the
    # toolset as unavailable even though the gateway has it.
    HERMES_CUA_DRIVER_CMD = "/run/current-system/sw/bin/cua-driver";
  };
}
