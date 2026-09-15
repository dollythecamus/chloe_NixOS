{ self, lib, ... }:

{
  # Record which commit of this flake the running system was built from.
  #
  # Without this, `system.configurationRevision` stays null, NixOS writes no
  # /run/current-system/configurationRevision, and `nixos-rebuild
  # list-generations` prints "Configuration Revision: Unknown" for every
  # generation -- verified on 2026-09-15: all 14 generations read Unknown, so a
  # generation could only be matched to a commit by build timestamp. With it,
  # `sudo nixos-rebuild list-generations` names the commit and `sudo
  # nixos-rebuild switch --rollback` plus git log tell the whole story.
  #
  # Self-hosted pattern from nixos-version(8): system.configurationRevision =
  # self.rev or "dirty".
  system.configurationRevision = self.rev or self.dirtyRev or null;
}
