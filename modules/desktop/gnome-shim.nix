{ config, pkgs, inputs, ... }:

{
  # GNOME desktop manager as a *shim*, not as a session.
  #
  # It supplies plumbing niri does not: gnome-keyring (the org.freedesktop.secrets
  # provider where Chrome profiles, gh tokens and git-credential-libsecret keep
  # their credentials), gcr-ssh-agent, accounts-daemon, evolution-data-server,
  # dconf, at-spi, and gvfs/localsearch as user services.
  #
  # It is NOT a desktop that can be logged into here: no GDM is enabled and
  # services.xserver.enable is false, so only niri.desktop is registered in
  # /run/current-system/sw/share/wayland-sessions. gnome-shell, gnome-control-center,
  # epiphany, gnome-software and friends are installed and in the closure anyway
  # (core-shell + core-apps), which is dead weight a full GNOME session would
  # actually use.
  #
  # The plasma output drops this file on purpose and re-declares the two pieces
  # that matter (keyring + gcr-ssh-agent) in modules/desktop/plasma.nix.
  services.desktopManager.gnome.enable = true;
}
