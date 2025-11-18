{config, pkgs, inputs, ...}:

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

  environment.systemPackages = [
    pkgs.winetricks

	# that's not how u install it
    # pkgs.dotnetCorePackages.runtime_9_0-bin # needs for KSA uwu

	# auth
    pkgs.gnome-keyring
    pkgs.seahorse
  ];

}
