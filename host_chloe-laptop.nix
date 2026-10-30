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
    
    ./modules/system-packages.nix
    ./modules/services.nix
    ./modules/programs.nix
    ./modules/network.nix

    # 2026-10-22: phone access (Tailscale mesh + Syncthing for the small
    # vaults). Owns both because they serve one purpose; ~/projects stays out
    # of sync on purpose -- see the header comment in that module.
    ./modules/remote-access.nix

    # 2026-09-23: revive the tree's existing modules/nix-ld.nix so dynamically
    # linked, non-nix executables can run. Hermes' browser toolset shells
    # agent-browser via `npx agent-browser`, and agent-browser's Linux binary
    # (and its Playwright Chromium) is a generic glibc build — it does not exec
    # on a stock NixOS because /lib64/ld-linux-x86-64.so.2 is the stub-ld
    # placeholder ("NixOS cannot run dynamically linked executables...").
    # The module sets NIX_LD + NIX_LD_LIBRARY_PATH and ships a real ld-linux,
    # so nix-ld-aware binaries run. Also required for anything else dropped
    # outside nix (npm-installed tools, appimages).
    ./modules/nix-ld.nix
]
  # Desktop layer. The daily output boots GNOME via GDM (modules/desktop/
  # gnome.nix, chosen 2026-10-14 after the Sway mission-control week was
  # reverted on main -- simplest stack that just works, owning the whole
  # desktop). ly + niri are the login manager and recovery session of the two
  # A/B fallback outputs only: their configuration is byte-identical to
  # before this change, so a working-of-record fallback remains reachable
  # from any generation's boot menu. (SDDM was tried for the plasma output on
  # 2026-09-15 and showed nothing at all -- see the WAYLAND_DISPLAY note in
  # modules/desktop/plasma.nix for the cause; modules/desktop/gnome.nix
  # carries the same PAM-unset for GDM's Wayland greeter.)
  ++ (if desktop == "gnome"
      then [ ./modules/desktop/gnome.nix ]
      else if desktop == "xfce"
      then [ ./modules/desktop/xfce.nix ./modules/desktop/ly.nix ]
      else [ ./modules/desktop/niri.nix ./modules/desktop/ly.nix ])
  ++ (if desktop == "plasma"
      then [ ./modules/desktop/plasma.nix ]
      else if desktop == "niri"
      then [ ./modules/desktop/gnome-shim.nix ]
      else [ ]);

  # The "sway-prototype" value of `desktop` is gone from this flake alongside
  # the reverted adoption (revert commit d037b73). The Sway/niri system +
  # Home Manager modules remain in the tree, imported only by the fallback
  # outputs (and, where not imported at all, alive in git history and on the
  # project branches). New files still need an explicit reachable import.

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
  
  # networking.* (hostname, NetworkManager, firewall) lives in
  # modules/network.nix as of 2026-10-20.

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
