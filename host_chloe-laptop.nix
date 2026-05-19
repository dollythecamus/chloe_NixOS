# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports = [
    ./host_chloe-laptop_hardware.nix
    ./secrets.nix
    ./xdg.nix

    ./hardware/nvidia.nix
    ./modules/users/chloe.nix

    ./modules/desktop/space-home.nix
    ./modules/desktop/niri.nix
    
    ./modules/system-packages.nix
    ./modules/services.nix 
    ./modules/programs.nix
    ./modules/syncthing.nix

    ./modules/godot.nix

    # nope! 
    # ./modules/llms.nix
    
  ];

  # Enable NTFS to use files in external hard drive
  boot.supportedFilesystems = [ "ntfs" ];

  # Enable Grub
  boot.loader = {
  	grub.enable = true;
  	grub.device = "nodev";
  	grub.useOSProber = true;
  	grub.efiSupport = true;
  	efi.efiSysMountPoint = "/boot";
  	efi.canTouchEfiVariables = true;
  };
  
  networking.hostName = "chloe-laptop"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Recife";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # important
  security.polkit.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
