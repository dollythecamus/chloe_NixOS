{ pkgs, inputs, config, lib, ... }:

{
  # niri config file
  xdg.configFile."niri/config.kdl".source = ./config/niri/config.kdl;

  home.packages = with pkgs; [

  ];
}
