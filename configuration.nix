
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
    (/home/chloe/NixOS + "/${hostname}.nix")
  ];
}
