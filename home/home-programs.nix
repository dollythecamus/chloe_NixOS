{config, pkgs, pkgs-unstable, inputs, ...}:

let
  # Idle suspend is skipped while the machine is on external power: plugged in
  # means long unattended stretches (the Hermes gateway stays reachable from
  # Discord) where the laptop must not sleep. Screen lock (720s) and panel-off
  # (600s) below still happen; lid-close on AC is handled in modules/services.nix
  # via logind (HandleLidSwitchExternalPower = "lock").
  #
  # MUST use shell builtins only. swayidle's unit sets PATH to bash's own bin
  # directory (no coreutils), so a coreutils call here fails *silently*: the
  # first version used `cat`, every read came back empty, the loop fell through
  # to "exit 1", and the machine suspended while plugged in. `read` needs no
  # PATH. Anything else in these scripts must be an absolute store path.
  # Any non-battery supply reporting online counts as external power: ACAD
  # (type Mains) and, when charging over USB-C PD, ucsi-source-psy (type USB).
  # BAT1 has no `online` attribute, so only external supplies can match.
  acOnline = pkgs.writeShellScript "ac-power-online" ''
    for p in /sys/class/power_supply/*; do
      kind=""
      state=""
      [ -r "$p/type" ] || continue
      read -r kind < "$p/type"
      [ "$kind" = Battery ] && continue
      [ -r "$p/online" ] || continue
      read -r state < "$p/online"
      [ "$state" = 1 ] && exit 0
    done
    exit 1
  '';

  # swayidle runs this at the 30min idle mark instead of suspending outright.
  # Both branches leave a breadcrumb in the journal (under swayidle.service) so a
  # later investigation can tell which one ran.
  idleSuspend = pkgs.writeShellScript "idle-suspend-unless-ac" ''
    if ${acOnline}; then
      echo "idle-suspend: on external power, suspend suppressed" >&2
      exit 0
    fi
    echo "idle-suspend: on battery, suspending" >&2
    exec ${pkgs.systemd}/bin/systemctl suspend
  '';
in

{
  imports = [
       # gamedev
        ./programs/unity.nix
        ./programs/godot.nix
        ./programs/blender.nix
       # general
        ./terminal.nix

       # gaming
  	./gaming.nix
  ];

  # notifications
  services.dunst = {
    enable = true;
  };

  # network applet: tray icon + dialogs (wifi password prompts, edit connections)
  # bluetooth applet is already autostarted by services.blueman (system)
  services.network-manager-applet.enable = true;

  # low/critical battery + charging notifications via upower (into dunst)
  services.poweralertd.enable = true;

  # idle: dim/lock/suspend. niri serves ext-idle-notify, which swayidle >=1.8
  # speaks. graphical-session.target works because niri's systemd generator
  # starts it for the session (same target as nm-applet above).
  # Suspend at 30min fires only while on battery (idleSuspend above); on AC the
  # machine stays awake and merely stays locked.
  services.swayidle = {
    enable = true;
    systemdTargets = [ "graphical-session.target" ];
    events = {
      "before-sleep" = "${pkgs.swaylock}/bin/swaylock -f";
      "lock" = "${pkgs.swaylock}/bin/swaylock -f";
    };
    timeouts = [
      # DPMS-off the outputs at 10min (wlopm), lock at 12min, suspend at 30min
      { timeout = 600; command = "${pkgs.wlopm}/bin/wlopm --off"; resumeCommand = "${pkgs.wlopm}/bin/wlopm --on"; }
      { timeout = 720; command = "${pkgs.swaylock}/bin/swaylock -f"; }
      { timeout = 1800; command = "${idleSuspend}"; }
    ];
  };

  programs.nixcord = {
    enable = true;
    vesktop.enable = true;
  };

  programs.obsidian = {
    enable = true;
    cli.enable = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # default browser: Chrome
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";
      # kept from the hand-written ~/.config/mimeapps.list
      "x-scheme-handler/lmstudio" = "LM-Studio.desktop";
      "x-scheme-handler/x-github-client" = "github-desktop.desktop";
      "x-scheme-handler/x-github-desktop-dev-auth" = "github-desktop.desktop";
    };
  };

  home.packages = with pkgs; [
    home-manager # make home-manager available for use in the terminal
    
    # rice
    wofi
    nvtopPackages.nvidia
    playerctl
    brightnessctl
    grim
    slurp
    glow
    pkgs-unstable.btop-cuda
    nvtopPackages.nvidia
    neocities
    vlc
    wl-clipboard
    nautilus
    peaclock
    starship # customizeable prompts for any shell
    bacon # rust compiler
    cargo-info # get data about rust packages from the internet without going through the browser
    rusty-man # rust docs in cli
    mask # command runner in a markdown file, woa
    presenterm # terminal slides presentation tool
    kew # music player
    qutebrowser # minimal web browser
        # torrent
        qbittorrent
# browser, office
        google-chrome
        librewolf # to replace by qute
	libreoffice 
      
        # art
        krita
        gimp 

        # music
        lmms

        # audio: routing/level GUI -- output & input device selection, per-device
        # profiles (analog/headset/etc.), per-app volume and stream routing.
        # Talks to the system-wide pipewire-pulse socket (/var/run/pulse/native).
        pavucontrol

        # dev
        github-desktop

        # desktop integration applets (nm-applet systemd service lives above;
        # nm-connection-editor is in the same package)
        networkmanagerapplet

        # 3d printer slicer (UltiMaker Cura 5.12, wrapped AppImage —
        # native cura was dropped from nixpkgs; binary is `cura`)
        cura-appimage

        # screen locker (the niri Super+Alt+L bind spawns this)
        swaylock
        # DPMS on/off for wayland (used by swayidle timeouts, Mod+Shift+S)
        wlopm
  ];

}
