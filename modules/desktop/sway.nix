{ pkgs, lib, ... }:
{
  # Niri and ly remain installed in this generation as a recovery session.
  # The proprietary NVIDIA driver drives eDP-1; Sway requires explicit opt-in
  # to its unsupported-GPU path. This is only a launch gate, not proof it works.
  programs.sway = {
    enable = true;
    extraOptions = [ "--unsupported-gpu" ];
    extraPackages = [ ];
    extraSessionCommands = ''
      unset WAYLAND_DISPLAY QT_QPA_PLATFORM
      export XDG_CURRENT_DESKTOP=sway
      export WLR_NO_HARDWARE_CURSORS=1
    '';
  };

  # Shared xdg.nix and niri.nix set these via PAM in every login session.
  # A compositor must not inherit WAYLAND_DISPLAY or select a nested backend.
  environment.sessionVariables = {
    WAYLAND_DISPLAY = lib.mkForce null;
    QT_QPA_PLATFORM = lib.mkForce null;
    # Session wrapper exports sway; Niri can set its own value on fallback.
    XDG_CURRENT_DESKTOP = lib.mkForce null;
  };
  xdg.portal.config.sway."org.freedesktop.impl.portal.Secret" = "gnome-keyring";
}
