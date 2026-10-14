{ config, pkgs, lib, ... }:

{
  # Home Manager settings that exist only for the GNOME daily desktop
  # (desktop == "gnome"; imported by the gnome arm of home/chloe.nix).
  dconf.enable = true;

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
