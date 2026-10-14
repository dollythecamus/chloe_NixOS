{ config, pkgs, lib, inputs, ... }:

{
  # The flake's own home-manager module provides the Hermes Desktop wiring
  # (`programs.hermes-agent.desktop`). "GNOME arm" is a misnomer in the
  # filename: `home/chloe.desktop.nix` imports this file UNCONDITIONALLY
  # (that is how the 3d683ee branch shipped it — the dconf/suspend block
  # below already lands in all three outputs the same way), so the desktop
  # app installs in the niri and plasma fallback outputs too.
  imports = [ inputs.hermes-agent.homeManagerModules.default ];

  # THIS `services.hermes-agent` is the HOME-module instance's option set —
  # a separate module system from the system-level one in modules/hermes.nix,
  # which keeps owning the real gateway. Its options are used here ONLY as
  # input to the desktop flavor: setting them creates no unit, no activation
  # and no config write (`gateway.enable` and `backend.mode` stay at their
  # "none" defaults, so every generated unit is skipped — see
  # homeManagerModules.nix, the `mkIf cfg.enable` guards).
  #
  # The desktop package bakes its backend runtime as
  # HERMES_DESKTOP_HERMES = <our hermes>. Without this flavor agreement it
  # would default to the flake's plain-#default runtime, which carries
  # neither the messaging/anthropic dependency groups nor the holographic
  # plugin's numpy — a degraded brain running beside the gateway. With the
  # options below, programs.hermes-agent.package = effectivePackage evaluates
  # to the SAME derivation the system gateway runs (same package base, same
  # groups, same numpy — hm-module effectivePackage = services.package
  # .override { extraDependencyGroups; extraPythonPackages }). The derivation
  # dedupes with the gateway's; no extra build.
  services.hermes-agent.extraDependencyGroups = [ "messaging" "anthropic" ];
  services.hermes-agent.extraPackages = [
    (pkgs.callPackage ../pkgs/lightpanda.nix { })
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.agent-browser
  ];
  services.hermes-agent.extraPythonPackages = [
    inputs.hermes-agent.packages.${pkgs.system}.default.python.pkgs.numpy
    (pkgs.callPackage ../pkgs/hermes-faster-whisper.nix {
      python = inputs.hermes-agent.packages.${pkgs.system}.default.python;
    })
  ];

  # GNOME daily-desktop-only settings: install the Electron app + XDG
  # launcher into home.packages. The launcher wrapper carries
  # HERMES_HOME=/home/chloe/.hermes with it (a GUI launcher reads no shell
  # profile), which is the bridge symlink to /var/lib/hermes/.hermes — the
  # single-owner state directory shared with the gateway.
  programs.hermes-agent.desktop.enable = true;

  # This laptop's hard constraint is "no automatic suspend": the firmware has
  # no S3 and s2idle resume hangs (every suspend needs a forced power-off; no
  # `PM: suspend exit` in the journal). Logind already answers
  # HandleLidSwitch=lock (modules/services.nix), but GNOME would additionally
  # auto-suspend after idle minutes on its OWN default
  # (org.gnome.settings-daemon.plugins.power sleep-inactive-{ac,battery}-type).
  # Refuse that: display blank + screensaver lock stay GNOME defaults, which
  # is the same idle policy the niri output had (dim/lock only).
  dconf.settings."org/gnome/settings-daemon/plugins/power" = {
    sleep-inactive-ac-type = "nothing";
    sleep-inactive-battery-type = "nothing";
  };
}
