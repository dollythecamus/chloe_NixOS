{config, pkgs, pkgs-unstable, inputs, desktop, lib, ...}:

let
  # Dayboard's Android app targets API 35. AGP 8.7.2 (android/build.gradle)
  # requires JDK 17 and defaults to Build Tools 34.0.0; include 35.0.0 too.
  androidSdk = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "35" ];
    buildToolsVersions = [ "34.0.0" "35.0.0" ];
    includeEmulator = false;
    includeSources = false;
    includeSystemImages = false;
    includeNDK = false;
  };
in
{
  # This is scoped to Home Manager's package set; the Android SDK is distributed
  # under Google's SDK license, separate from allowUnfree.
  nixpkgs.config.android_sdk.accept_license = true;
  home.sessionVariables = {
    ANDROID_HOME = "${androidSdk.androidsdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk.androidsdk}/libexec/android-sdk";
  };
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

  # Desktop-session pieces -- niri's, not Plasma's. XFCE also excludes the
  # Wayland idle/lock daemons. home/chloe.desktop.nix intentionally keeps
  # importing desktop-gnome.nix for Hermes desktop wiring; its dconf blocks are
  # inert under XFCE. In the plasma generation the session owns all four roles
  # itself: plasmashell *is* the notification daemon and the tray
  # (network/battery/bluetooth applets), and powerdevil + kscreenlocker own idle
  # and locking. Running the niri-era daemons there would
  # put two processes behind org.freedesktop.Notifications (one loses the name
  # and logs it) and double the tray. In the Sway prototype, nm-applet and
  # poweralertd are dropped rather than repaired:
  #   * nm-applet needs a tray to dock into (the prototype EWW panel is a
  #     non-focusable text surface with no tray), and it died for weeks with
  #     "cannot open display" before that was traced; nmtui (Super+Shift+N)
  #     covers the workflow. NetworkManager itself, portals and notification
  #     routing are untouched.
  #   * poweralertd needs a notification daemon alive at start; Dunst (kept)
  #     serves that role.
  # `desktop` comes from the flake's home-manager.extraSpecialArgs.
  services.dunst.enable = desktop != "plasma" && desktop != "gnome" && desktop != "xfce";
  services.network-manager-applet.enable =
    desktop != "plasma" && desktop != "gnome" && desktop != "sway-prototype";
  services.poweralertd.enable =
    desktop != "plasma" && desktop != "gnome" && desktop != "sway-prototype";
  services.swayidle.enable = desktop != "plasma" && desktop != "gnome" && desktop != "xfce";

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
    timeouts = lib.mkIf (desktop != "sway-prototype") [
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
    # Android/Capacitor builds: JDK 17 is required by AGP 8.7.2; the project
    # supplies its own Gradle 8.11.1 wrapper, but keep Gradle available too.
    jdk17
    gradle
    androidSdk.androidsdk
    home-manager # make home-manager available for use in the terminal
    
    # rice
    wofi
    # nvtopPackages.nvidia removed 2026-10-22: it dragged cuda-merged-12.9 (the
    # whole CUDA toolkit, ~67 derivations) into every `nix flake update nixpkgs`,
    # because the nvidia variant is not on cache.nixos.org. Verified with
    # `nix why-depends --derivation <system.drv> <cuda_nvrtc.drv>` and by a
    # dry-build that showed zero cuda entries once it was gone. GPU monitoring
    # stays covered by pkgs-unstable.btop-cuda below and nvidia-smi from the driver.
    playerctl
    brightnessctl
    grim
    slurp
    glow
    pkgs-unstable.btop-cuda
    # signal-desktop removed 2026-10-22: never worked on this machine, and
    # 8.15.0 bundled RingRTC 2.69.3 (< 2.72.0, CVE-2026-113380: a caller can
    # flood the call FSM queue so a hangup never tears down mic/camera) on a
    # months-old Electron. Signal on the phone is the real client.
    vlc
    wl-clipboard
    nautilus
    starship # customizeable prompts for any shell
    # torrent
    qbittorrent
    # browser, office
    google-chrome
    librewolf
 	  libreoffice 
      
    # art
    krita
    gimp 
    # pixel-art / animated-sprite editor (Aseprite fork). nixpkgs 1.2, gpl2Only,
    # platforms.all -- evaluated against the pinned nixpkgs on 2026-10-27.
    libresprite

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
