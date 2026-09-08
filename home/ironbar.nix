{ pkgs, config, lib, ... }:

let
  colors = config.lib.stylix.colors.withHashtag;

  ironbarStyle = builtins.replaceStrings
    [ "@bg@" "@bg2@" "@fg@" "@accent@" "@alert@" ]
    [ colors.base00 colors.base02 colors.base05 colors.base0D colors.base08 ]
    (builtins.readFile ./dotfiles/config/ironbar/style.css);
in
{
  xdg.configFile."ironbar/config.yaml".source = ./dotfiles/config/ironbar/config.yaml;

  # style.css is templatized (@tokens@) so the bar tracks the stylix palette
  # (kanagawa) instead of hardcoded colors.
  xdg.configFile."ironbar/style.css".text = lib.mkIf config.stylix.enable ironbarStyle;

  home.packages = with pkgs; [
  	(pkgs.ironbar.overrideAttrs (oldAttrs: {
    	cargoBuildFlags = (oldAttrs.cargoBuildFlags or []) ++ [ "--features" "niri" ];
  	}))
  	# install the ironbar package with the niri features
  ];
}
