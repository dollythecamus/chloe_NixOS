{ config, lib, pkgs, ... }:

{
  # KDE Plasma 6 -- the second desktop stack (host output chloe-laptop-plasma).
  # niri stays installed and its session file stays registered, so SDDM offers
  # both and a bad Plasma session is one logout away from the old one.

  services.desktopManager.plasma6.enable = true;

  # The plasma6 module configures SDDM's package, theme and Wayland compositor,
  # but does NOT enable it (checked in the pinned module
  # nixos/modules/services/desktop-managers/plasma6.nix -- there is no
  # sddm.enable in it). ly is not imported in this output: two display managers
  # cannot both be enabled.
  services.displayManager.sddm.enable = true;

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
  # niri's set. "KDE" is Plasma's own value and matches the portal config key
  # above. Generation-scoped: a niri session started from *this* generation also
  # reports KDE, and would then use the common (wlr;gnome;gtk) portal list -- the
  # niri output is unaffected.
  environment.sessionVariables.XDG_CURRENT_DESKTOP = lib.mkForce "KDE";
}
