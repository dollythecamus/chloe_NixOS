{ pkgs, inputs, config, lib, ... }:

{
  # niri config file
  xdg.configFile."niri/config.kdl".source = ./dotfiles/config/niri/config.kdl;

  home.packages = with pkgs; [

  ];
}
