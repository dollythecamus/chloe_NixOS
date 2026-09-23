{config, pkgs, pkgs-unstable, inputs, desktop, ...}:

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

  # Desktop-session pieces -- niri's, not Plasma's. In the plasma generation the
  # session owns all four roles itself: plasmashell *is* the notification daemon
  # and the tray (network/battery/bluetooth applets), and powerdevil +
  # kscreenlocker own idle and locking. Running the niri-era daemons there would
  # put two processes behind org.freedesktop.Notifications (one loses the name
  # and logs it) and double the tray. `desktop` comes from the flake's
  # home-manager.extraSpecialArgs.
  services.dunst.enable = desktop != "plasma";
  services.network-manager-applet.enable = desktop != "plasma";
  services.poweralertd.enable = desktop != "plasma";
  services.swayidle.enable = desktop != "plasma";

  # idle: dim/lock only -- NO automatic suspend (see below). niri serves
  # ext-idle-notify, which swayidle >=1.8 speaks. graphical-session.target works
  # because niri's systemd generator starts it for the session (same target as
  # nm-applet above).
  services.swayidle = {
    # `enable` is set by the desktop branch above
    systemdTargets = [ "graphical-session.target" ];
    events = {
      "before-sleep" = "${pkgs.swaylock}/bin/swaylock -f";
      "lock" = "${pkgs.swaylock}/bin/swaylock -f";
    };
    timeouts = [
      # DPMS-off the outputs at 10min, lock at 12min. No suspend timeout: every
      # suspend on this laptop has hung (no `PM: suspend exit` in the journal
      # history, forced power-off each time), so nothing automatic may suspend it
      # until that is fixed. Deliberate suspends (rtcwake, `systemctl suspend`)
      # still work for testing.
      # niri's own power-off/on-monitors actions: `wlopm --off` needs an output
      # name, so the old line only ever logged "ERROR: '--off' needs an output
      # name" and the panel never blanked. NIRI_SOCKET is in swayidle's env
      # (verified on the live process).
      { timeout = 600; command = "${pkgs.niri}/bin/niri msg action power-off-monitors"; resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors"; }
      { timeout = 720; command = "${pkgs.swaylock}/bin/swaylock -f"; }
    ];
  };

  programs.nixcord = {
    enable = true;
    vesktop.enable = true;
    # Vesktop is used without Vencord/Equicord injected by choice; nixcord
    # otherwise warns on every eval about the "no mod client" combination.
    discord.silenceNoModClientWarning = true;
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

        # vtuber (Inochi2D): creator = puppet editor (.INP), session =
        # the runtime that drives a puppet live for OBS
        inochi-creator
        inochi-session
        openseeface

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
        # DPMS on/off for wayland. No config uses it any more: the swayidle
        # timeouts and Mod+Shift+S/Mod+Shift+P all use niri's own
        # power-off/on-monitors actions (wlopm --off requires an output name).
        # Kept for manual use only.
        wlopm
  ];

}
