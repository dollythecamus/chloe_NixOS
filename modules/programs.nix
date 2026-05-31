{config, pkgs, system, inputs, ...}:

{
  # Programs

  # Steam
  programs.steam = {
    enable = true;
    protontricks.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  
  #programs.adb = {
  #  enable = true;
  #};

  # Git
  programs.git = {
    enable = true;
    config = {
        credential.helper = "${ pkgs.git.override { withLibsecret = true; } }/bin/git-credential-libsecret";
      };
  };

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = [
      # pkgs.obs-studio-plugins._pluginnamehere
    ];
  };

  environment.systemPackages = [
    pkgs.ffmpeg
    pkgs.winetricks
    pkgs.protonvpn-gui
    pkgs.pipewire
    pkgs.android-tools

	# that's not how u install it
    # pkgs.dotnetCorePackages.runtime_9_0-bin # needs for KSA uwu

    # auth
    pkgs.gnome-keyring
    pkgs.seahorse
  ];

  environment.sessionVariables = {
    FFMPEG_PATH = "${pkgs.ffmpeg}";
    EDITOR = "nvim";
    TERMINAL = "kitty";
  };

  # overlay for blender to use GPU in rendering
  # without this, renders only on iGPU
  /*
  	# i wish there were a way to use vulkan for gpu instead, the way it is now, i have to compile the whole cuda support for it and sometimes it fails a idk why
  nixpkgs.overlays = [
    (final : prev: {
      blender = prev.blender.override {
	cudaSupport = true;
      };
     }
  )];
  */

}
