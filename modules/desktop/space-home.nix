{config, pkgs, inputs, ...}:

{
  # xkb layout for X11 and for compositors that read the system setting: niri's
  # config.kdl leaves its own xkb section empty and fetches the system's, and
  # /etc/X11/xorg.conf.d/00-keyboard.conf is written even though xserver.enable
  # is false. (KWin does not read that file -- Plasma has its own layout setting
  # in System Settings -> Input Devices -> Keyboard.)
  services.xserver.xkb = {
    layout = "us,br";
    variant = "";
  };

  # GNOME desktop manager used to live here as a patchwork shim for niri's
  # missing plumbing. It now lives in ./gnome-shim.nix, imported only by the niri
  # output, so the Plasma generation can drop it without losing xkb/pathsToLink.
  environment.pathsToLink = [
    "/share/xdg-desktop-portal" "/share/applications"
  ];

}
