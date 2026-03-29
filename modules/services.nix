{config, pkgs, inputs, ...}:

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

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  services.power-profiles-daemon.enable = false;

  # laptop battery power savings
  services.tlp = {
  enable = true;
  settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
  };
};

}
