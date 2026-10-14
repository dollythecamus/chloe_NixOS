{ lib, ... }:

{
  # GNOME + GDM: the daily desktop since 2026-10-14.
  #
  # Operator decision after d037b73 (revert of the 2026-10-12 Sway
  # mission-control adoption): the simplest stack that just works, owning the
  # desktop entirely on this output. ly, Sway, niri, EWW/Ironbar and the
  # mission-control rice are not imported here; ly + niri stay the login
  # manager and recovery session of the two A/B fallback outputs only
  # (chloe-laptop-niri, chloe-laptop-plasma), which are byte-identical to
  # before this change.
  #
  # Roles the session owns itself -- the corresponding Home Manager services
  # are gated off for desktop == "gnome" in home/home-programs.nix:
  #   notifications -> GNOME Shell (dunst off)
  #   idle/lock     -> gsd + org.gnome.desktop.screensaver (swayidle/swaylock
  #                    off; the idle-auto-suspend refusal lives in
  #                    home/desktop-gnome.nix)
  #   status tray   -> quick settings (nm-applet/poweralertd off)
  services.displayManager.gdm.enable = true;
  # NOTE: gdm.wayland does not exist here (removed at the GNOME 50 bump --
  # the build fails the assertion "Disabling this option is no longer
  # supported with GNOME 50"); GDM always greets via Wayland in this pin.
  services.desktopManager.gnome.enable = true;

  # ★ PAM environment trap -- same mechanism that black-screened Plasma on
  # 2026-09-15 (full story in modules/desktop/plasma.nix). The shared root
  # xdg.nix sets WAYLAND_DISPLAY=wayland-0 and QT_QPA_PLATFORM=wayland via
  # environment.sessionVariables; those land in /etc/pam/environment and reach
  # EVERY session, including the display manager's greeter. GDM runs its own
  # Wayland greeter compositor; a stale WAYLAND_DISPLAY makes greeter children
  # point at a socket that does not exist. Unset both for this desktop
  # (mkForce to beat the shared value; also matches what the Sway and Plasma
  # outputs already do).
  environment.sessionVariables = {
    WAYLAND_DISPLAY = lib.mkForce null;
    QT_QPA_PLATFORM = lib.mkForce null;
    # Likewise unset the niri value: gnome.desktop carries DesktopNames=GNOME,
    # and portal + GTK theme selection key off XDG_CURRENT_DESKTOP (the
    # rendered portal file is named after its lowercased value).
    XDG_CURRENT_DESKTOP = lib.mkForce null;
  };

  # Portals. The shared root xdg.nix installs xdg-desktop-portal-gnome and
  # -gtk (extraPortals) and sets config.common.default = ["wlr" "gnome" "gtk"],
  # so the GNOME desktop would fall through "wlr" first for interfaces wlr
  # lacks. Give the GNOME desktop its own scoped config (file rendered as
  # gnome-portals.conf from XDG_CURRENT_DESKTOP lowercased, the mechanism the
  # Plasma generation verified live), with the keyring as the Secret provider
  # -- the keyring Chrome, gh and git-credential-libsecret credentials
  # already live in, same as plasma.nix.
  xdg.portal.config.gnome = {
    default = [ "gnome" "gtk" ];
    "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
  };

  # TLP stays the power manager (modules/services.nix keeps
  # power-profiles-daemon disabled explicitly, and that explicit false beats
  # the gnome module's mkDefault ppd-on). Firewall: never re-enable ppd in a
  # GNOME generation without disabling TLP -- nixpkgs asserts the two cannot
  # coexist.
}
