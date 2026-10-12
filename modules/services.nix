{config, pkgs, system, inputs, ...}:

{
  # Services

  # Tablet driver: OpenTabletDriver was tried and disabled (commented); the
  # xserver.wacom option was removed 2026-10-12 -- xserver.enable is false in
  # every output, so it never applied anything.

  xdg.portal.enable = true;
  xdg.portal.xdgOpenUsePortal = true;
  # services.flatpak removed 2026-10-12: zero flatpak apps installed since the
  # system was set up (2026-09-05), only 7 empty stale ~/.var/app scaffolds.
  # Portals are kept -- they serve non-flatpak apps too (portal-gnome is the
  # top file-open path in recently-used.xbel).

  # blueman removed 2026-10-12 -- bluetuith (Super+I, mission-control F01) owns
  # bluetooth; blueman-applet also has no tray to dock into in the prototype.

  # CUPS removed 2026-10-12: no printer has ever been configured (no printers
  # in /etc/cups/printers.conf, no ppds, empty page_log since install) while
  # cupsd + cups-browsed ran at every boot.

  #enable docker
  virtualisation.docker = {
    enable = true;
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    systemWide = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.power-profiles-daemon.enable = false;

  # Lid close: lock the screen, never sleep -- on battery and on external power
  # alike. Every suspend on this laptop hangs and needs a forced power-off (no
  # `PM: suspend exit` anywhere in the journal history), so until that is fixed
  # nothing automatic may suspend it; the idle path is covered by dropping the
  # suspend timeout in home/home-programs.nix. Deliberate suspends (rtcwake,
  # `systemctl suspend`) still work for testing the wake failure.
  # HandleLidSwitchExternalPower is "completely ignored by default"
  # (logind.conf(5)) -- with no explicit value logind falls back to
  # HandleLidSwitch, whose built-in default is "suspend" -- so both arms must be
  # set explicitly. niri takes no low-level "handle-lid-switch" lock (its login1
  # watcher only reads LidClosed for switch-events), so logind is the actor.
  # "lock" makes logind lock all sessions -> swayidle's "lock" event runs
  # swaylock -f.
  services.logind.settings.Login = {
    HandleLidSwitch = "lock";
    HandleLidSwitchExternalPower = "lock";
  };

  # laptop battery power savings
  services.tlp = {
  enable = true;
  settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    };
  };

  # hamachi vpn
  services.logmein-hamachi.enable = true;
  programs.haguichi.enable = true;

}
