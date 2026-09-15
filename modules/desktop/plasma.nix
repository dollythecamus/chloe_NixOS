{ config, lib, pkgs, ... }:

{
  # KDE Plasma 6 -- the second desktop stack (host output chloe-laptop-plasma).
  # niri stays installed and its session file stays registered, so the login
  # manager lists BOTH sessions and a bad Plasma session is one logout away from
  # the old one.
  #
  # The display manager is deliberately ly in this generation, the same one the
  # niri generation boots today (modules/desktop/ly.nix is imported by both
  # branches). ly reads ${sessionData.desktops}/share/wayland-sessions, which
  # contains plasma.desktop and niri.desktop, so the login path is unchanged and
  # the Plasma session is a menu entry in a greeter that is known to come up on
  # this laptop. SDDM was tried first and produced no login screen at all: see
  # the WAYLAND_DISPLAY note below for the reason. SDDM is expected to work now
  # that the cause is known (and the plasma6 module already configures it), but
  # it is not worth spending another unbootable cycle on in the same change.
  services.desktopManager.plasma6.enable = true;

  # ★ WAYLAND_DISPLAY=wayland-0 and QT_QPA_PLATFORM=wayland are set system-wide
  # in the shared session-variable modules (root xdg.nix). Those go through PAM
  # -- environment.sessionVariables land in /etc/pam/environment and are "set by
  # PAM early in the login process" -- so they reach EVERY session, including the
  # display manager's greeter and the Plasma session itself.
  #
  # KWin reads WAYLAND_DISPLAY and concludes it must use its NESTED Wayland
  # backend instead of DRM. The 2026-09-15 plasma boot (journal, boot -1) logged
  # exactly this and then displayed nothing -- no greeter, no crash, no error:
  #
  #   sddm-helper-start-wayland[2408]: "No backend specified, automatically
  #     choosing Wayland because WAYLAND_DISPLAY is set"
  #
  # Unset both here so KWin selects its DRM backend. Neither is needed: niri
  # exports its own WAYLAND_DISPLAY to its children (and strips the stale one --
  # it logs "running as a session but WAYLAND_DISPLAY is set, removing it"),
  # startplasma-wayland sets the Qt platform itself, and Qt 6 detects Wayland
  # without being told. The niri generation keeps the old values untouched: there
  # niri already overrides them, and that session works.
  # null means "unset" for sessionVariables ("You can override a variable set by
  # another module to null to unset it"), hence mkForce to beat the shared value.
  environment.sessionVariables = {
    WAYLAND_DISPLAY = lib.mkForce null;
    QT_QPA_PLATFORM = lib.mkForce null;
  };

  # Portals. The root xdg.nix sets the *global* default to niri's set
  # (wlr;gnome;gtk) and nixpkgs' niri module writes niri-portals.conf, so a
  # Plasma session would otherwise fall through to niri's backends. The rendered
  # file is named after XDG_CURRENT_DESKTOP lowercased (verified live:
  # config.niri -> /etc/xdg/xdg-desktop-portal/niri-portals.conf), hence the `kde`
  # key and the "KDE" session value below.
  # Secret stays on gnome-keyring: that is the keyring the existing credentials
  # are in, and KWallet is not adopted in this generation.
  xdg.portal.config.kde = {
    default = [ "kde" "gtk" ];
    "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
  };

  # Plumbing that the GNOME shim used to provide (modules/desktop/gnome-shim.nix).
  # Dropping the shim must not drop the secret store, the ssh-agent or the file
  # manager's virtual filesystem (nautilus is in home.packages; without gvfs it
  # loses trash/remote/MTP integration). Deliberately NOT re-added: localsearch +
  # tinysparql (the Tracker indexers the shim started -- 335 MB RSS when observed),
  # so file *search* inside nautilus stays off in this generation.
  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = true;
  services.gvfs.enable = true;

  # XDG_CURRENT_DESKTOP is hardcoded to "niri" by the shared session-variable
  # modules (root xdg.nix and modules/desktop/niri.nix). In a Plasma session that
  # mislabels the desktop and would make portal and GTK-theme selection pick
  # niri's set. "KDE" is Plasma's own value (plasma.desktop carries
  # DesktopNames=KDE) and matches the portal config key above. Generation-scoped:
  # a niri session started from *this* generation also reports KDE, and would
  # then use the common (wlr;gnome;gtk) portal list -- the niri output is
  # unaffected.
  environment.sessionVariables.XDG_CURRENT_DESKTOP = lib.mkForce "KDE";
}
