{ pkgs, inputs, config, lib, ... }:

{
  # niri config file
  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;

  home.packages = with pkgs; [

  ];
}