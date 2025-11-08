
{
  config,
  pkgs,
  options,
  ...
}: let
  hostname = "chloe-nixos"; # to alllow per-machine config
in {
  networking.hostName = hostname;

  imports = [
    /etc/nixos/hardware-configuration.nix
    (/home/chloe/dotfiles/nixos + "/${hostname}.nix")
  ];
}

# this file isn't really used anymore :3

