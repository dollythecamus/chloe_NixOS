# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, desktop, ... }:

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
    
  ]
  # Desktop layer. Both stacks keep niri and the shared session bits; they differ
  # in the login manager and in whether the GNOME desktop-manager shim is on.
  # `desktop` comes from the flake's specialArgs (nixosConfigurations.chloe-laptop
  # = "niri", .chloe-laptop-plasma = "plasma").
  ++ (if desktop == "plasma"
      then [ ./modules/desktop/plasma.nix ]
      else [ ./modules/desktop/gnome-shim.nix ./modules/desktop/ly.nix ]);

  # Garbage collection. Until now there was no policy at all: 75 GiB in
  # /nix/store and the root filesystem at 85% (42 GiB free). Weekly, dropping
  # generations older than 14 days; the *boot menu* keeps the 10 most recent
  # entries regardless (GRUB's default configurationLimit is 100). Note the two
  # are independent: configurationLimit limits the menu, nix.gc decides what is
  # reclaimable.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  # Hardlink identical files in the store. With two nixpkgs pins (26.05 and
  # nixpkgs-unstable for hermes-agent/lmstudio/btop-cuda) the same sources land
  # twice -- linux-firmware, nvidia-x11, clang libs and cef-binary are all in the
  # store twice -- and this is what stops that doubling.
  nix.settings.auto-optimise-store = true;

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

  # Suspend-to-disk hibernation into /swapfile (16 GiB >= ~11.4 GiB RAM). This is
  # the only sleep path left on this laptop: the firmware advertises
  # "ACPI: PM: (supports S0 S4 S5)" -- no S3 -- so suspend can only be s2idle,
  # and s2idle resume is broken here (2026-09-15: `rtcwake -m mem -s 90` left the
  # machine dead even with an independent RTC wake source; no `PM: suspend exit`
  # appears anywhere in the journal from Sep 5 onward). Hibernation itself has
  # never been exercised on this machine: the journal has no image save/load,
  # no systemd-hibernate run and no hibernate request reaching logind, so nothing
  # is known yet about whether it works. logind's CanHibernate reports "yes".
  #
  # boot.resumeDevice = the filesystem holding the swapfile (root ext4 -> the
  # nvme0n1p4 UUID); the initrd then adds resume=DEV to the kernel cmdline. The
  # swapfile's first extent must additionally be passed as resume_offset=N
  # (both are needed to find the image at boot).
  # NOTE: if the swapfile is ever recreated with a different geometry, re-run
  #   sudo filefrag -v /swapfile
  # and update resume_offset = <extent 0 physical offset> / 4096.
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
  	# Keep the boot menu to 10 entries (GRUB's default is 100). The store keeps
  	# generations for 14 days per nix.gc above -- the two limits are independent.
  	grub.configurationLimit = 10;
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
