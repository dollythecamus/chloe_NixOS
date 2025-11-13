{config, pkgs, unstablePkgs, inputs, ...}:

{

  programs.yazi = {
	enable = true;
	enableFishIntegration = true;
	# home-manager is in the unstable now so i think this is not needed
	# package = unstablePkgs.yazi; # from unstable is better apparently
	settings = {
		opener = {
			edit = [{ run = "nvim %n"; orphan = true; block = true; for = "unix"; }];
		};

	};
  };
}
