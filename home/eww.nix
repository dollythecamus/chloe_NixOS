{config, pkgs, inputs, ...} :

{
  # EWW STUFF I WANT:

  # time, date, calendar
  # battery
  # workspaces
  # power 
  # audio

  # yay !
  xdg.configFile."eww" = {
    source = ./dotfiles/config/eww;
    recursive = true;
  };

  programs.eww = {
	enable = true;
	#enableFishIntegration = true;
  };
}
