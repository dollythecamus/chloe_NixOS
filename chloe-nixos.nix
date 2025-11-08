# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  # enable systemd-boot again
  boot.loader.systemd-boot.enable = true;

  # Enable NTFS to use files in external hard drive
  boot.supportedFilesystems = [ "ntfs" ];

  # Enable Grub
  # fuckoff with grub, something bad happened
  #boot.loader = {
  #	grub.enable = true;
  #	grub.device = "nodev";
  #	grub.useOSProber = true;
  #	grub.efiSupport = true;
  #	efi.efiSysMountPoint = "/boot";
  #	efi.canTouchEfiVariables = true;
  #};
  
  # networking.hostName = "chloe"; # Define your hostname.
  # hostname already defined, it's fine
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # i'm not supposed to commit the changes. the rebuild script will handle that.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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

  # Nvidia Configuration

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    open = false;

    # Enable the Nvidia settings menu,
	  # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.nvidia.prime = {
	  offload = {
      enable = true;
      enableOffloadCmd = true;
	  };
	  nvidiaBusId = "PCI:1:0:0";
	  amdgpuBusId = "PCI:54:0:0";

  };

	# End of Nvidia Configuration

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Enable Hyprland
  programs.hyprland.enable = true;

  # Enable Electron apps for wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,br";
    variant = "";
  };

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
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account.
  users.users.chloe = {
      isNormalUser = true;
      description = "Chloe Amanita Nomad";
      extraGroups = [ "networkmanager" "wheel" "dialout" "bluetooth" "input"];
      packages = with pkgs; [
      # Gaming                
        prismlauncher
        ckan
        lutris
        wine

      # Misc
        discord
        qbittorrent
        element-desktop
        drawpile # collaborative drawing :3

      # Productivity
        obsidian
        libreoffice # office pack
      
      # Creation
        polyphone
        krita
        godot # godot with Orchestrator
        unstable.godot
        unstable.godot-mono

        libresprite

        librewolf

        blender
        audacity
        lmms
        # reaper # sound design # it is NOT FREE ! OH NO !
        freecad
        inkscape # FOSS Vector Graphics
        gimp # FOSS Image Editor
        gmic-qt
        gmic
        # unstable.cura-appimage # Ultimaker Cura for 3D prints
          # seems to screw up nixos rebuild as well as cudatoolkit
        pureref

      # Development
        thonny # rpi pico dev
      	vscode # VSCode!
        github-desktop
      ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # override blender for CUDA hardware acceleration
  nixpkgs.overlays = [
  	 (final : prev: {
		  blender = prev.blender.override {
			  cudaSupport = true;
		 	  };
	   }
	)];
	# overrides blender to use CUDA hardware acceleration (render with NVIDIA GPU)

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
	
  # oxidise - Rust packages
    uutils-coreutils # GNU coreutils
    fish # command line shell
    # nushell # another command line shell
    fd # alternative to find
    bat # cat, but better (idk what cat is
    eza # alternative to ls
    zoxide # smarter cd
    zellij # interesting ui
    gitui # git ui 
    dust # pretty disk analyzer
    starship # customizeable prompts for any shell
    yazi # interesting file manager
    bacon # rust compiler
    cargo-info # get data about rust packages from the internet without going through the browser
    unstable.ncspot # spotify, but awesome # unstable because it is broken in stable
    rusty-man # rust docs in cli
    wiki-tui # wikipedia in cli! how queer!
    mask # command runner in a markdown file, woa
    presenterm # terminal slides presentation tool 

  # need some
    killall

  # Hyprland 
    kitty
    waybar
    dunst
    wofi
    sway
    nwg-look
    swww

    wl-clipboard # copy paste features
    
    playerctl # control media player
    brightnessctl # control brighness
    
    hyprpolkitagent
    hyprlock
    
    networkmanager
    #qt5-wayland
    #qt6-wayland

    input-remapper # to use the cool mouse that doesn't work but looks cool

  # Misc
    adwaita-icon-theme # Adwaita icon theme
    font-awesome # font awesome for waybar icons 
    neocities # for working with my neocities website  
    neofetch
    neovim
    
    wacomtablet # drawing tablet
    
    ffmpeg # media converter uwu
    yt-dlp # youtube video downloader
    vlc # video player
    
    python312

    grim # for screenshots
    slurp # also

    cudatoolkit # CUDA hardware acceleration, blender as well as Ollama
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Services

  # enable flatpak
  services.flatpak.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  #enable bluetooth manager
  services.blueman.enable = true;

  # Enabling syncthing to synchronize my folders across devices
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "chloe";
    group = "users";
    dataDir = "/home/chloe/.config/syncthing"; # Syncthing's internal data/config 

    settings = {
      # Define all your devices here using their actual Syncthing Device IDs
      devices = {
        "amanita-mobile" = {
          id = "W54WQWG-B4EPE7H-F5WYUHX-FB3OMKO-GZHUCHS-NQXEFIG-KXMIQBX-CJIEDA3"; 
        };

        # "portable-chloe" = {
        #   id = "undefined"; # undefined -- has to be inserted here later.
        # };
        # Add more devices as needed
      };

      # Define all shared folders here

      folders = {
        "Media" = {
          path = "~/Mix/Media";
          devices = ["amanita-mobile"];
        };

        "Mind" = {
          path = "~/Mix/Mind";
          devices = ["amanita-mobile"];
        };

        "Inventions" = {
          path = "~/Mix/Inventions";
          devices = ["amanita-mobile"];
        };

        "College" = {
          path = "~/Mix/College";
          devices = ["amanita-mobile"];
        };

      };
    };
  };

  # Programs

  # Install firefox. actually, don't
  # programs.firefox.enable = true;

  # Install Steam.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  
  programs.git = {
  	enable = true;
    config = {
        credential.helper = "${ pkgs.git.override { withLibsecret = true; } }/bin/git-credential-libsecret";
      };	
  };

  # temporary, insecure packages:
  # this package should have an updated secure version, so, whatthehell

  nixpkgs.config.permittedInsecurePackages = [
    "mbedtls-2.28.10"
  ];


  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
