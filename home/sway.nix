{ pkgs, lib, ... }:
let
  petPackage = pkgs.callPackage ../pkgs/termagotchi.nix { };
  control = "${pkgs.bash}/bin/bash $HOME/.config/mission-control/control.sh";
  terminal = "${control} terminal";
  launcher = "${control} launcher";
  pet = "${control} terminal --class mission-pet --title mission-pet ${petPackage}/bin/termagotchi";
  # Opt-in launchers: keep ordinary desktop entries/backends until the real
  # drag-and-drop/tablet acceptance tests pass. Absolute paths avoid recursion.
  lmmsX11 = pkgs.writeShellScriptBin "lmms-x11" ''
    export QT_QPA_PLATFORM=xcb
    exec ${pkgs.lmms}/bin/lmms "$@"
  '';
  kritaX11 = pkgs.writeShellScriptBin "krita-x11" ''
    export QT_QPA_PLATFORM=xcb
    exec ${pkgs.krita}/bin/krita "$@"
  '';
  godotX11 = pkgs.writeShellScriptBin "godot-x11" ''
    exec ${pkgs.godot}/bin/godot --display-driver x11 "$@"
  '';
  godotSingleWindow = pkgs.writeShellScriptBin "godot-single-window" ''
    exec ${pkgs.godot}/bin/godot --single-window "$@"
  '';
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
  home.packages = [ petPackage lmmsX11 kritaX11 godotX11 godotSingleWindow ];
  xdg.desktopEntries = {
    lmms-x11 = {
      name = "LMMS (X11 compatibility)";
      exec = "${lmmsX11}/bin/lmms-x11 %f";
      icon = "lmms";
      categories = [ "AudioVideo" "Audio" ];
      terminal = false;
    };
    krita-x11 = {
      name = "Krita (X11 compatibility)";
      exec = "${kritaX11}/bin/krita-x11 %F";
      icon = "krita";
      categories = [ "Graphics" "2DGraphics" ];
      terminal = false;
    };
    godot-x11 = {
      name = "Godot (X11 compatibility)";
      exec = "${godotX11}/bin/godot-x11 --project-manager";
      icon = "godot";
      categories = [ "Development" "IDE" ];
      terminal = false;
    };
    godot-single-window = {
      name = "Godot (single-window compatibility)";
      exec = "${godotSingleWindow}/bin/godot-single-window --editor %f";
      icon = "godot";
      categories = [ "Development" "IDE" ];
      terminal = false;
    };
  };

  wayland.windowManager.sway = {
    enable = true;
    # HM owns configuration; the NixOS wrapper owns the session entry, GPU
    # opt-in and environment. Keep an HM package for build-time config validation.
    systemd.enable = false;
    # In practice the session launches THIS package, not the NixOS module's
    # wrapper: the ly session PATH puts /etc/profiles/per-user/chloe/bin (HM)
    # ahead of /run/current-system/sw/bin, so programs.sway.extraOptions never
    # reaches the running binary. Sway 1.12's NVIDIA gate is a non-fatal
    # swaynag (sway main.c) but still interrupts startup, so the flag has to
    # ride the wrapper that actually executes.
    extraOptions = [ "--unsupported-gpu" ];
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
        # A user-set mkOptionDefault binding overrides the Home Manager
        # default for that key; keys left unset keep the HM defaults
        # (live-verified: Mod4+b beats the default splith while the
        # untouched defaults still bind Mod4+e/s/w/v). A binding set to
        # null is disabled outright — plain removal is not enough for
        # Mod4+d, whose HM default is the menu launcher itself.
        "Mod4+Return" = "exec ${terminal} ${pkgs.fish}/bin/fish";
        "Mod4+e" = "exec ${launcher}";
        "Mod4+d" = null;
        "Mod4+x" = "kill";
        "Mod4+t" = "exec ${control} theme";
        "Mod4+b" = "exec ${control} expand";
        "Mod4+p" = "exec ${pet}";
        "Mod4+o" = "exec ${orbits}";
        "Mod4+F1" = "exec ${control} keys";
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
      # Store path: Home Manager can validate the include before activation.
      include ${./dotfiles/config/mission-control/creative-windows.conf}
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
