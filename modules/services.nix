{config, pkgs, inputs, ...}:

{
  # Services

  # enable flatpak
  # services.flatpak.enable = true;
  # xdg.portal.enable = true;

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
}
