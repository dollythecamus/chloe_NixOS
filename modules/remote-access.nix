{ ... }:

{
  # Remote device access -- phone (Android) to this host, added 2026-10-22.
  # Why the shape: ~/projects is 42 GB of Unity work (three Git LFS repos, one
  # project 23 GB) across 13 repositories, so it is deliberately NOT synced --
  # a phone clone would ship Library/, Builds/ and LFS blobs over mobile data
  # and conflict on .meta files the first time both sides edit. The phone reads
  # big trees over SFTP and commits over SSH instead; only the small vaults
  # (~/Mind 2.1 MB, ~/wiki 2.6 MB) are synced. Write-up:
  # ~/wiki/entities/phone-project-access.md

  # Mesh VPN: a stable 100.x address from any network (no port forwarding, no
  # DDNS). Chosen over the logmein-hamachi daemon that has sat installed with
  # zero networks joined since install -- Android allows only one active VPN
  # and Tailscale is the one that is maintained and has a NixOS module.
  # Activation is manual and one-time: `sudo tailscale up` (no auth key is
  # stored in the tree, so no key file to rotate).
  services.tailscale.enable = true;

  # Anything arriving from the tailnet is trusted: SSH on 22 and Syncthing's
  # 22000 then work from the phone without opening a single port to the LAN or
  # the internet. sshd itself is already on (secrets.nix) -- nothing new to
  # enable for git-over-SSH.
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Syncthing carries the notes only (Obsidian on the phone needs a real local
  # vault). Runs as chloe with her home as the data dir so the shared folders
  # are the vaults themselves and there is no second copy under /var/lib to
  # keep straight; group stays `users` (her primary group) instead of the
  # module's default `syncthing` group. openDefaultPorts stays false because
  # LAN discovery is not needed and the tailnet is already trusted.
  services.syncthing = {
    enable = true;
    user = "chloe";
    group = "users";
    dataDir = "/home/chloe";
    configDir = "/home/chloe/.config/syncthing";
    openDefaultPorts = false;
  };

  # 2026-10-22: password logins off now that the phone key is in
  # ~chloe/.ssh/authorized_keys and `ssh pc` authenticates by key from Termux
  # (verified end-to-end). Revert this one line if any other device turns out
  # to rely on a password login.
  services.openssh.settings = {
    PasswordAuthentication = false;
    # PasswordAuthentication=no alone does not close the door: with UsePAM=true
    # sshd would still offer keyboard-interactive, which is the same password
    # prompt under another name. Both have to be off for key-only to be real.
    KbdInteractiveAuthentication = false;
  };
}
