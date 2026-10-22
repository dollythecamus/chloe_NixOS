# Stationeers — hosting a game from chloe-laptop: fix plan

Written 2026-10-20. Scope: making `Host Server` in the Stationeers client reachable by
friends outside the LAN, from this NixOS machine.

> **Identifiers are placeholders, deliberately.** This file is committed to a public repository,
> so the measured values appear as `<wan-ipv4>`, `<lan-ipv4>`, `<gateway-mac>` and
> `<isp-reverse-dns>`. Re-derive them on the host when you actually run the steps:
> `curl -s https://api.ipify.org` (public), `ip -4 -o addr show wlo1` (LAN),
> `ip neigh show 192.168.0.1` (router MAC). Do not paste the real values back into this file.

## Verdict

Yes — hosting requires port forwarding. Not because of Proton, but because of the transport
shape: Stationeers runs its own RakNet build ("rocketnet") over **plain direct UDP** since the
Jan-2026 Multiplayer Update. There is no Steam relay to fall back on, and no matchmaking server
that would proxy the traffic. Inbound UDP must reach the host, which means two hops:

1. **router**: WAN → `<lan-ipv4>` (UDP 27015 + 27016)
2. **host firewall**: NixOS `firewall.service` (currently default: only TCP 22 allowed)

Proton contributes nothing to this path — Wine maps Winsock onto Linux sockets, and the game
never speaks SteamNetworkingSockets for this connection. If the two forwards above are correct,
a Windows friend will connect exactly as to a Windows host.

## Measured on this machine (2026-10-20)

| Probe | Result | Consequence |
|---|---|---|
| Stationeers install | **not installed**, no `compatdata/544550` | step 0 installs it; prefix path below is created on first launch |
| LAN address | `wlo1 <lan-ipv4>/24`, DHCP (`dynamic`) | address can move; forwarding breaks until it's pinned (step 1) |
| Extra IPv4 | `docker0 172.17.0.1/16` present | game host-IP auto-detection can advertise `172.17.0.1` → pin `LocalIpAddress` (step 4) |
| Gateway | `192.168.0.1`, MAC `<gateway-mac>` → **Huawei** | Claro-supplied ONT or a Huawei router; admin UI did **not** answer on 80/443/8080/8443/8000/7547 from Wi-Fi |
| UPnP | no IGD answered SSDP (multicast **and** unicast M-SEARCH) | the in-game `UPNPEnabled` checkbox is very likely a dead end here → manual forward |
| ISP / public IPv4 | Claro/NET AS28573 (`<isp-reverse-dns>`), public **<wan-ipv4>**, Recife | a real public IPv4 is assigned to *something*; whether it's on your router's WAN needs the router UI (step 3 gate) |
| IPv6 | public `2804:14d:…`, default route via `fe80::1` | irrelevant — Stationeers is IPv4-only |
| NixOS firewall | `firewall.service` active + enabled, no `networking.firewall` config in `~/nixos`; nixpkgs `programs.steam` already opens UDP 27015/27036/10400-1 and the 27031-27035 range | **27016 was the only missing port** → every forwarded game packet died in the firewall |

## Ports

`setting.xml` keys: `GamePort` (default **27016**, player traffic) and `UpdatePort` (default
**27015**, Steam query). Both UDP. The community wiki's direct-connect example uses 27016; a
hosting-provider guide swaps the two. Forward **both** — it costs nothing and covers either
reading of the labels.

## Steps

### 0 — Install and host once, before changing anything

Install Stationeers (Proton Experimental is fine — version choice does not affect reachability),
start a world with `Host Server` ticked, then check that it binds at all:

```bash
ss -lunp | grep -iE 'rocketstation|2701[56]'
```

- No listener → game-side problem; stop, nothing below will help. Report back with the log.
- Listener on `0.0.0.0:27016` or `172.17.0.1:27016` → note which, it tells you whether step 4 is
  compulsory (the `172.17.0.1` case is: the game is bound to the docker bridge, unreachable).

Baseline first means you can tell "still broken" from "was never bound".

### 1 — Pin the LAN address

Either add a DHCP reservation on the router for `wlo1`'s MAC, or configure a static address.
Everything downstream (forwarding target, `LocalIpAddress`) hardcodes `<lan-ipv4>`, so it must
not drift. Verify the MAC:

```bash
ip -o link show wlo1 | awk '{print $17}'
```

### 2 — Open the port in the NixOS firewall (done — verify with a rebuild)

Networking policy now lives in `~/nixos/modules/network.nix`, imported by the host file. It
took over `networking.hostName`, `networking.networkmanager.enable` and adds:

```nix
  networking.firewall.allowedUDPPorts = [ 27015 27016 ];
```

Verify it evaluated into the config (already run, result below):

```bash
nix eval --json .#nixosConfigurations.chloe-laptop.config.networking \
  --apply 'n: n.firewall.allowedUDPPorts'
# → [5353,10400,10401,27015,27016,27036]   (5353=avahi, 10400/10401/27036/27015=steam)
```

Then, in your terminal:

```bash
sudo nixos-rebuild switch --flake ~/nixos#chloe-laptop
```

Afterwards confirm the live ruleset picked it up:
`sudo iptables-save | grep 2701` (or `sudo nft list ruleset`) — expect ACCEPT for UDP 27015
and 27016.

### 3 — Forward on the router (this is the part only you can do)

Gate check first, from the router's **Internet / WAN status** page:

| WAN IPv4 shown there | Meaning | Action |
|---|---|---|
| `<wan-ipv4>` (same as the internet sees) | single NAT, public address | continue below |
| `100.64.x.x` – `100.127.x.x` | carrier-grade NAT | forwarding cannot work — go to step 6 |
| `10.x.x.x` / `172.16–31.x.x` / `192.168.x.x` | **another router in front** (Claro ONT before the Huawei, e.g.) | forward on the outer device too, or DMZ the inner router onto the outer one, then retest |

Then, on the router:

1. Port-forward rule, protocol **UDP**, external `27015` → `<lan-ipv4>:27015`
2. Port-forward rule, protocol **UDP**, external `27016` → `<lan-ipv4>:27016`
3. Leave UPnP alone — it did not answer here, so don't rely on the game's checkbox
4. If the admin UI refuses to answer on this machine (it did on 80/443/8080/8443/8000/7547):
   try from a wired port, or the vendor app / label on the device. A Huawei ONT often serves
   the UI on a LAN-side port that Wi-Fi client isolation hides.

### 4 — Pin the advertised local IP

Because `docker0` exists, the game's host-IP auto-detection can pick `172.17.0.1` (upstream has
patched this repeatedly: *"Changed Get IPv4Address to use the raknet functions… Filtered out
loopback addresses"*). In the game: Settings screen → set the port explicitly; then edit, after
the first launch has created it:

```
~/.local/share/Steam/steamapps/compatdata/544550/pfx/drive_c/users/steamuser/Documents/My Games/Stationeers/setting.xml
```

```xml
<LocalIpAddress><lan-ipv4></LocalIpAddress>   <!-- was empty -->
<GamePort>27016</GamePort>
<UPNPEnabled>false</UPNPEnabled>
```

Restart the game after editing.

### 5 — Verify

1. Host again, then confirm the bind is on the LAN address, not docker:
   `ss -lunp | grep 27016` → expect `0.0.0.0:27016` or `<lan-ipv4>:27016`.
2. Friend joins by **Direct Connect** with `<wan-ipv4>:27016`.
3. Outcome matrix:

| Symptom | Layer at fault |
|---|---|
| Immediate "connection refused"/timeout, no packet on host | router forward missing or aimed at the wrong IP |
| Works from LAN, never from outside | WAN side: forward, double NAT, or CGNAT |
| Packet arrives, game never answers | NixOS firewall still blocking (`sudo nft list ruleset \| grep 2701`) |
| Binds `172.17.0.1` only | step 4 not applied |
| Friend connects then desyncs/drops | not networking-to-the-host; post in-game log |

Note: testing from your own machine via the public IP requires the router to hairpin NAT; a
failure there does **not** mean the forward is broken. Test from the friend's side or a phone
hotspot.

### 6 — Fallback if the router is locked down or you're behind CGNAT

Skip forwarding entirely and put both machines on one overlay network:

- **Tailscale** (or ZeroTier): install on this laptop and on the friend's PC, then the friend
  uses Direct Connect with `100.x.y.z:27016` from `tailscale status`. No router access needed.
- The wiki's own advice (a tunnelling service) is the same idea with worse tooling; Hamachi is
  explicitly reported as unreliable.

This is also the cheapest **diagnostic**: if the tunnel works and the public IP doesn't, the
problem was always reachability — never Proton.

## Not in scope

Steam-P2P defects (`steam-for-linux#13715` ICE relay-only, `#12641`, the `SendP2PRendezvous`
`lsteamclient` drift) do not apply to Stationeers hosting — the game bypasses Steam networking
for this connection, so no Proton version changes are part of this plan.

## Rollback

- Remove the `allowedUDPPorts` block, rebuild — port closed again.
- Delete the two router forward rules.
- Revert `LocalIpAddress` to empty if you switch to a different host machine.
