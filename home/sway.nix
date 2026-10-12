{ pkgs, lib, ... }:
let
  petPackage = pkgs.callPackage ../pkgs/termagotchi.nix { };
  control = "${pkgs.bash}/bin/bash $HOME/.config/mission-control/control.sh";
  terminal = "${control} terminal";
  launcher = "${control} launcher";
  # F01: keyboard Bluetooth manager. One TUI is added; Blueman stays installed
  # upstream as the declared fallback for unsupported pairing flows.
  bluetoothTui = "${terminal} --class mission-bluetooth --title mission-bluetooth ${pkgs.bluetuith}/bin/bluetuith";
  # F02: notification history/DND through the already-running Dunst.
  notifications = "${pkgs.dunst}/bin/dunstctl";
  # F03: grim/slurp/wl-copy helper (mission-control/screenshots.py).
  screenshot = "${control} screenshot";
  # F04: clipboard history picker lives in control.sh (`clipboard` command);
  # cliphist binaries are referenced directly in the keybinding.
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
  home.packages = with pkgs;
    [ petPackage lmmsX11 kritaX11 godotX11 godotSingleWindow ]
    ++ [
      # F01 Bluetooth: one TUI manager (Blueman fallback stays system-wide).
      bluetuith
      # F04 Clipboard history: bounded session-only store under XDG state.
      cliphist
      # F07 Audio mixer TUI (pavucontrol stays as the GUI fallback).
      pulsemixer
      # F06 Display profiles + layout GUI fallback; wl-mirror pending NVIDIA
      # verification before it may be advertised.
      kanshi
      wdisplays
      # F10 Removable storage stays scripted; no automount daemon by accident.
      udiskie
      # F15 Scanner + printer status entry points.
      simple-scan
    ];
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
    # The supported Home Manager integration owns the session lifecycle: it
    # emits the DBus/systemd environment import plus sway-session.target
    # start/stop commands at config load, and installs the own target. This
    # replaces /etc/sway/config.d/nixos.conf's equivalent lines and guarantees
    # WAYLAND_DISPLAY/SWAYSOCK reach systemd-user + D-Bus activation BEFORE
    # graphical-session.target starts dependent services (the exact condition
    # that skipped swayidle and killed nm-applet/dunst/poweralertd on this
    # login). It is the single startup owner — no competing helper script.
    # In practice the session launches the HM package, not the NixOS module's
    # wrapper: the ly session PATH puts /etc/profiles/per-user/chloe/bin (HM)
    # ahead of /run/current-system/sw/bin. Sway 1.12's NVIDIA gate is a
    # non-fatal swaynag (sway main.c) but still interrupts startup, so the
    # flag rides the wrapper that actually executes.
    systemd.enable = true;  # explicit, not the default-by-omission
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
        # Read-only command panes: hotkeys are the primary controls, not buttons.
        "Mod4+BackSpace" = "exec ${control} widget home";
        "Mod4+n" = "exec ${control} widget network";
        "Mod4+m" = "exec ${control} widget audio";
        # Hide the EWW layer to give tiled windows the full output without
        # setting Sway's per-window fullscreen state.
        "Mod4+f" = "exec ${control} toggle-visibility";
        "Mod4+Shift+f" = "fullscreen toggle";
        "Mod4+Shift+l" = "exec ${pkgs.swaylock}/bin/swaylock -f";
        # Phase B — everyday essentials. Every routing decision (BT list,
        # roster/history, clipboard entries, storage devices, mounts) is made
        # by the focused UI; hotkeys open the application, never execute
        # selected data.
        # Lenovo P1/P2 hardware keys are NOT bound: xkeyboard-config has no
        # `P1`/`P2` keysym names and the Ideapad extra-buttons device emits raw
        # evdev codes that need a live press test (operator present, evtest/web)
        # to identify. Blocked-with-reason, not silently disabled. The session
        # menu is reachable at Mod4+Escape and from the panel hint.
        # F01 Bluetooth.
        "Mod4+i" = "exec ${bluetoothTui}";
        # F02 Notifications: history roster.
        "Mod4+u" = "exec ${notifications} history";
        # F03 Screenshots.
        "XF86Select" = "exec ${screenshot} area";
        "Mod4+Pause" = "exec ${screenshot} output";
        # F04 Clipboard history.
        "Mod4+v" = "exec ${control} clipboard";
        # F05 Session menu — no suspend entry (broken resume; see Roadmap).
        "Mod4+Escape" = "exec ${control} session";
        # F06 Display outputs — kanshi profiles selected inside the TUI.
        "Mod4+Control+d" = "exec ${terminal} --class mission-display --title mission-display ${pkgs.kanshi}/bin/kanshi";
        # F07 Audio mixer TUI.
        "Mod4+Shift+a" = "exec ${terminal} --class mission-audio --title mission-audio ${pkgs.pulsemixer}/bin/pulsemixer";
        # F10 Removable storage.
        "Mod4+Delete" = "exec ${control} storage";
        # F12 Input: layout summary falls back to exit-code 2 until live input
        # identity is wired; only the indicator is advertised for now.
        "Mod4+Shift+i" = "exec ${control} layout";
        # F18 System maintenance overview.
        "Mod4+Shift+s" = "exec ${control} system";
        "Mod4+Shift+n" = "exec ${terminal} --class mission-network --title mission-network ${pkgs.networkmanager}/bin/nmtui";
        "Mod4+Control+n" = "exec ${control} action wifi-toggle";
        "Mod4+bracketleft" = "exec ${control} action volume-down";
        "Mod4+bracketright" = "exec ${control} action volume-up";
        "Mod4+Shift+m" = "exec ${control} action sink-mute";
        "Mod4+Control+m" = "exec ${control} action source-mute";
        "XF86AudioRaiseVolume" = "exec ${control} action volume-up";
        "XF86AudioLowerVolume" = "exec ${control} action volume-down";
        "XF86AudioMute" = "exec ${control} action sink-mute";
        "XF86AudioMicMute" = "exec ${control} action source-mute";
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
  # Named commands (Dunst, nm-applet, poweralertd) stay tied to
  # graphical-session.target and inherit the import that the HM sway
  # integration performs before that target starts.
  services.swayidle.timeouts = lib.mkForce [
    { timeout = 600; command = "${pkgs.sway}/bin/swaymsg 'output * dpms off'";
      resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms on'"; }
    { timeout = 720; command = "${pkgs.swaylock}/bin/swaylock -f"; }
  ];

  # F04 — cliphist watcher. Bounded, session-only store under XDG_RUNTIME
  # state so it cannot survive a logout as a permanent log; max 200 entries,
  # images included. The watcher dies with the graphical session.
  systemd.user.services.mission-cliphist = {
    Unit = {
      Description = "mission-control clipboard history (bounded, session-only)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
    Service = {
      ExecStart = "${pkgs.cliphist}/bin/cliphist watch";
      Environment = [
        "CLIPHIST_DB=${"$"}{XDG_STATE_HOME:-$HOME/.local/state}/mission-control/cliphist.db"
      ];
      Restart = "on-failure";
      RestartSec = "2s";
    };
  };
}
