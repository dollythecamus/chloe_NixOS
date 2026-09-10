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
    ./modules/desktop/ly.nix
    
    ./modules/system-packages.nix
    ./modules/services.nix 
    ./modules/programs.nix
    
  ];

  # Compressed RAM swap, priority 100 > the 16 GiB disk swapfile's 10, so
  # zram is consumed before anything hits the disk. zstd is the best
  # compressing of the algorithms the module accepts; memoryPercent left at
  # its default of 50 (= ~5.7 GiB of backing store on this 11.4 GiB machine,
  # which is a cap on stored pages, not a RAM reservation).
  zramSwap = {
    enable = true;
    priority = 100;
    algorithm = "zstd";
  };

  # Suspend-to-disk hibernation using /swapfile (16 GiB >= ~98% of 11.4 GiB RAM).
  # Root ext4 UUID -> nvme0n1p4. boot.resumeDevice makes the initrd generator add
  # resume=DEV to the kernel cmdline; the swapfile's physical extent offset must be
  # passed as resume_offset=N (systemd's hibernate-resume needs both).
  # NOTE: if the swapfile is ever recreated with a different geometry, re-run
  #   sudo filefrag -v /swapfile
  # and update resume_offset = <extent 0 physical> / 4096.
  boot.resumeDevice = "/dev/disk/by-uuid/7dc941d5-0e7c-4380-acf7-4dde1adbd8e5";
  boot.kernelParams = [ "resume_offset=4272128" ];

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

  # big downloads
  nix.settings.download-buffer-size = 524288000;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
