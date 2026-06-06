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

  environment.systemPackages = with pkgs; [
    ffmpeg
    winetricks
    proton-vpn
    pipewire
    
    # auth
    gnome-keyring
    seahorse
  ];

  environment.sessionVariables = {
    FFMPEG_PATH = "${pkgs.ffmpeg}";
    EDITOR = "nvim";
    TERMINAL = "kitty";
  };

}
