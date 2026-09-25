{ pkgs, lib, ... }:
let
  petPackage = pkgs.callPackage ../pkgs/termagotchi.nix { };
  control = "${pkgs.bash}/bin/bash $HOME/.config/mission-control/control.sh";
  terminal = "${control} terminal";
  launcher = "${control} launcher";
  pet = "${control} terminal --class mission-pet --title mission-pet ${petPackage}/bin/termagotchi";
  orbits = "${control} terminal --class mission-orbits --title mission-orbits ${pkgs.python3}/bin/python3 $HOME/.config/mission-control/orbits.py";
in
{
  # This file is imported only by chloe-laptop-sway-prototype. The other
  # outputs still import their existing Niri/EWW/Ironbar configuration.
  stylix.targets.kitty.enable = lib.mkForce false;
  stylix.targets.wofi.enable = lib.mkForce false;
  xdg.configFile."mission-control" = {
    source = ./dotfiles/config/mission-control;
    recursive = true;
  };
  programs.eww.enable = true;
  home.packages = [ petPackage ];

  wayland.windowManager.sway = {
    enable = true;
    # HM owns configuration; the NixOS wrapper owns the session entry, GPU
    # opt-in and environment. Keep an HM package for build-time config validation.
    systemd.enable = false;
    config = {
      modifier = "Mod4";
      terminal = terminal;
      menu = launcher;
      bars = [ ]; # EWW alone owns workspace/status; no Ironbar or Sway bar.
      gaps.inner = 0;
      gaps.outer = 0;
      window.border = 2;
      input."type:touchpad" = {
        tap = "enabled";
        natural_scroll = "enabled";
      };
      input."type:keyboard" = {
        xkb_layout = "us,br";
        xkb_options = "grp:win_space_toggle,compose:ralt,ctrl:nocaps";
      };
      output."eDP-1" = {
        resolution = "1920x1080@60.001Hz";
        scale = "1";
      };
      # Sway has no native per-workspace tile cap. The IPC guard relocates
      # overflow leaves without restricting floating windows.
      startup = [
        { command = "${control} start"; always = true; }
        { command = "${pkgs.python3}/bin/python3 $HOME/.config/mission-control/workspace_guard.py"; }
      ];
      keybindings = lib.mkOptionDefault {
        "Mod4+Return" = "exec ${terminal}";
        "Mod4+d" = "exec ${launcher}";
        "Mod4+t" = "exec ${control} theme";
        "Mod4+b" = "exec ${control} expand";
        "Mod4+p" = "exec ${pet}";
        "Mod4+o" = "exec ${orbits}";
        "Mod4+F1" = "exec ${control} keys";
        "Mod4+q" = "kill";
        "Mod4+Shift+f" = "fullscreen toggle";
        "Mod4+Shift+l" = "exec ${pkgs.swaylock}/bin/swaylock -f";
        "Mod4+Shift+n" = "exec ${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
        "Mod4+Shift+a" = "exec ${pkgs.pavucontrol}/bin/pavucontrol";
        "XF86AudioRaiseVolume" = "exec ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioLowerVolume" = "exec ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioMute" = "exec ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set +5%";
        "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
      };
    };
    extraConfig = ''
      include /etc/sway/config.d/*
      default_orientation horizontal
      # When plugged in, reserve the sidebar only on the built-in monitor.
      # External outputs keep their full work area and independent workspaces.
      workspace 1 output eDP-1
    '';
  };

  # Niri's idle command is invalid in Sway. No suspend: s2idle resume is broken.
  services.swayidle.timeouts = lib.mkForce [
    { timeout = 600; command = "${pkgs.sway}/bin/swaymsg 'output * dpms off'";
      resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms on'"; }
    { timeout = 720; command = "${pkgs.swaylock}/bin/swaylock -f"; }
  ];
}
