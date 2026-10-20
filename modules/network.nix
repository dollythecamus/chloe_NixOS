{ ... }:

{
  # Networking, in one place. Moved out of host_chloe-laptop.nix on 2026-10-20;
  # the host file keeps boot/identity options, this module owns network policy.

  networking.hostName = "chloe-laptop"; # Define your hostname.

  # NetworkManager owns Wi-Fi/Ethernet. Consumers: nmtui (Super+Shift+N in the
  # niri output), network-manager-applet (home/home-programs.nix), and the
  # "networkmanager" group in modules/users/chloe.nix.
  networking.networkmanager.enable = true;

  # Stationeers hosting (docs/stationeers-hosting-plan.md). The game runs its own
  # RakNet over plain UDP: GamePort 27016 carries player traffic, UpdatePort 27015
  # the Steam query. NixOS drops inbound by default and, unlike Windows, never
  # prompts a game to punch a hole -- 27016 was the one genuinely missing here, so a
  # forwarded packet arrived at the NIC and died in nftables. 27015 is already opened
  # by nixpkgs' programs/steam.nix; it is listed anyway so both of the game's ports
  # are visible in one place instead of depending on the Steam module's internals.
  networking.firewall.allowedUDPPorts = [ 27015 27016 ];
}
