{config, pkgs, pkgs-unstable, inputs, ...}:

{
  imports = [
        # gamedev
         ./programs/unity.nix
         ./programs/godot.nix
         ./programs/blender.nix
        # 3d printing
         ./programs/crealityprint.nix
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
      { timeout = 1800; command = "${pkgs.systemd}/bin/systemctl suspend"; }
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

        # vtuber (Inochi2D): creator = puppet editor (.INP), session =
        # the runtime that drives a puppet live for OBS
        inochi-creator
        inochi-session

        # music
        lmms

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
