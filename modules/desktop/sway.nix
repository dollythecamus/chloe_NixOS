{ pkgs, lib, ... }:
{
  # Niri and ly remain installed in this generation as a recovery session.
  # The proprietary NVIDIA driver drives eDP-1. Sway 1.12's unsupported-GPU
  # gate is a non-fatal swaynag dialog (sway main.c), not a launch refusal.
  # This wrapper is normally shadowed: the ly session PATH resolves `sway` to
  # the Home Manager profile wrapper first, so the flag on the launched binary
  # comes from wayland.windowManager.sway.extraOptions in home/sway.nix. This
  # module still owns the session entry and the PAM environment clean-up.
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
