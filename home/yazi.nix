{config, pkgs, inputs, ...}:

{

  programs.yazi = {
	enable = true;
	enableFishIntegration = true;
	# package = ; 
	settings = {
	};
  };
}
