{config, pkgs, inputs, ...}:

{

  programs.yazi = {
	enable = true;
	enableFishIntegration = true;
	# package = ; 
	settings = {
		opener = {
			edit = [{ run = "nvim %n"; orphan = true; block = true; for = "unix"; }];
		};

	};
  };
}
