{ lib, ... }:

{
  # XFCE/X11 recovery desktop for Hermes computer_use (cua-driver), whose
  # full capture/input path on this host requires an X11 session. The daily
  # GNOME output and the existing niri/Plasma outputs remain separate. The
  # Home Manager wrapper still imports desktop-gnome.nix for Hermes desktop
  # wiring; its dconf-specific blocks are inert in XFCE.
  services.xserver.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  # Keep XFCE's experimental Wayland session disabled; ly should offer X11 only.

  # The shared xdg.nix exports these through PAM into every session, including
  # the display-manager greeter. Clear stale Wayland/Qt values and identify this
  # desktop so X11 applications and portal selection resolve correctly.
  environment.sessionVariables = {
    WAYLAND_DISPLAY = lib.mkForce null;
    QT_QPA_PLATFORM = lib.mkForce null;
    XDG_CURRENT_DESKTOP = lib.mkForce "XFCE";
  };

  xdg.portal.config.xfce = {
    default = [ "gtk" ];
    "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
  };

  # Preserve the existing credential store, ssh agent and GVFS integration
  # without importing the GNOME desktop or its session manager.
  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = true;
  services.gvfs.enable = true;

  # 2026-11-02: computer_use on X11 needs the AT-SPI bridge. With this off the
  # module exports NO_AT_BRIDGE=1 / GTK_A11Y=none (so no app exposes an
  # accessibility tree) and cua-driver's doctor reports "org.a11y.Bus not
  # reachable". Enabling it installs at-spi2-core and activates org.a11y.Bus in
  # the session; apps started afterwards expose their element tree.
  services.gnome.at-spi2-core.enable = true;

  # 2026-10-29: the Hermes gateway system unit runs as chloe with
  # HOME=/var/lib/hermes and has no XAUTHORITY. Permit its local CUA driver to
  # connect to this single-user laptop's X server; keep -nolisten tcp intact.
  # Append rather than replace: the pinned server args already include required
  # -config/-xkbdir/:0 values.
  services.xserver.displayManager.xserverArgs = lib.mkAfter [ "-ac" ];
}
