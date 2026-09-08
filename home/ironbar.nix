{ pkgs, inputs, ...}:

{
  
  xdg.configFile."ironbar/config.yaml".source = ./dotfiles/config/ironbar/config.yaml;
  xdg.configFile."ironbar/style.css".source = ./dotfiles/config/ironbar/style.css;


  home.packages = with pkgs; [
  	(pkgs.ironbar.overrideAttrs (oldAttrs: {
    	cargoBuildFlags = (oldAttrs.cargoBuildFlags or []) ++ [ "--features" "niri" ];
  	}))
  	# install the ironbar package with the niri features
  ];
}

