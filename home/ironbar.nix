{ pkgs, inputs, ...}:

{
  
  xdg.configFile."ironbar/config.yaml".source = ./config/ironbar/config.yaml; 

  home.packages = with pkgs; [
  	(pkgs.ironbar.overrideAttrs (oldAttrs: {
    	cargoBuildFlags = (oldAttrs.cargoBuildFlags or []) ++ [ "--features" "niri" ];
  	}))
  	# install the ironbar package with the niri features
  ];
}

