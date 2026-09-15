{config, pkgs, system, inputs, ...}:

{
  # Services

  # Enable OpenTabletDriver
  #hardware.opentabletdriver.enable = true;

  services.xserver.wacom.enable = true;

  # enable flatpak
  services.flatpak.enable = true;
  xdg.portal.enable = true;
  xdg.portal.xdgOpenUsePortal = true;

  #enable bluetooth manager
  services.blueman.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

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

  # Lid close: on battery suspend (unchanged); on external power lock only, never
  # sleep. HandleLidSwitchExternalPower is "completely ignored by default"
  # (logind.conf(5)) -- with no explicit value logind falls back to HandleLidSwitch,
  # whose built-in default is "suspend" -- so the value must be set explicitly.
  # niri takes no low-level "handle-lid-switch" lock (its login1 watcher only reads
  # LidClosed for switch-events), so logind is the actor for the lid. "lock" makes
  # logind lock all sessions -> swayidle's "lock" event runs swaylock -f.
  # Idle suspend is a separate actor (swayidle); see home/home-programs.nix.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
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
