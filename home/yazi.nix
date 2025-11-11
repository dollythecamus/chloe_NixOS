{config, pkgs, inputs, ...}:

{

  programs.yazi = {
	enable = true;
	enableFishIntegration = true;
	settings = {
		opener.edit = [{ run = "nvim %s"; }];
	};
  
  };

}
