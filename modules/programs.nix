{config, pkgs, system, inputs, ...}:

{
  imports = [
  ];
  
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
    lfs.enable = true;
    config = {
        credential.helper = "${ pkgs.git.override { withLibsecret = true; } }/bin/git-credential-libsecret";
      };
  };

  # KDE Connect (2026-11-02): phone <-> laptop link over the Tailscale mesh
  # rather than the LAN. Discovery is UDP broadcast, which a tailnet does not
  # carry, so pairing uses explicit addresses instead (phone: "Add devices by
  # IP" -> 100.73.119.21; laptop: custom address 100.64.240.27 pushed over
  # D-Bus). modules/remote-access.nix already trusts tailscale0, so the mesh
  # path needs no port rules; the range below is what nixpkgs' module adds on
  # every interface, which also keeps ordinary LAN pairing working at home.
  # The package ships /etc/xdg/autostart/org.kde.kdeconnect.daemon.desktop, so
  # kdeconnectd starts with the GNOME session (pathsToLink carries /etc/xdg).
  programs.kdeconnect.enable = true;

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
    openssl
  ];

  environment.sessionVariables = {
    FFMPEG_PATH = "${pkgs.ffmpeg}";
    EDITOR = "nvim";
    TERMINAL = "kitty";
  };

}
