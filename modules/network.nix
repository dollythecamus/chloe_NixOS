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

  # Jellyfin (projects/hy320-debloat, docs/JELLYFIN.md): the server runs as chloe's
  # user unit on 0.0.0.0:8096, but the TV stick on the same LAN could not open the
  # port -- measured 2026-11-03, box -> 192.168.0.132:22 connects and :8096 times
  # out, i.e. the firewall, not the app. Inbound blocking is the whole point of the
  # firewall, so the one port the box needs is named here rather than disabled.
  #
  # 2026-11-09: scoped to the house LAN (192.168.0.0/24 on wlo1) instead of
  # allowedTCPPorts, which opens a port on *every* interface -- the same library
  # would then be served to whatever wifi this laptop joins next. Two backends
  # matter here: this host has networking.nftables.enable = false, so it is the
  # iptables firewall doing the work, and `firewall.extraInputRules` exists only
  # in the nftables module -- setting it eval's clean and is silently ignored,
  # i.e. the port stays shut. `extraCommands` is the iptables-side hook and is
  # appended to nixos-fw just before its final log-refuse, so an unmatched
  # source still gets dropped. Plain `iptables`, not `ip46tables`: the source
  # prefix is IPv4-only. The tailnet needs no rule of its own --
  # modules/remote-access.nix trusts tailscale0.
  #
  # This stops working if the router's subnet changes or the laptop goes wired;
  # the failure direction is "the stick cannot reach Jellyfin", never "the port
  # is open somewhere unexpected".
  networking.firewall.extraCommands = ''
    iptables -w -A nixos-fw -i wlo1 -s 192.168.0.0/24 -p tcp --dport 8096 -j nixos-fw-accept
  '';
}
