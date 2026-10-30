{ config, ... }:

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

    # 2026-10-29: the vaults become declarative. Until now the module only ran the
    # daemon and the folders were expected as a GUI click, so a rebuild from a
    # clean configDir left them unshared. `settings` is applied by the module's own
    # activation script through the REST API, and `overrideFolders` defaults to
    # true: any folder not listed here is deleted on activation, so the web UI is a
    # viewer for these entries, not a second source of truth. Same for devices:
    # the phone is declared rather than clicked, or the next activation un-pairs it.
    #
    # The ID below is a public-key fingerprint (SHA-256 of the phone's cert), not a
    # credential -- holding it grants no access, the private key stays on the phone.
    # It is published deliberately (Chloe, 2026-10-29) after weighing the alternative
    # (pairing in the GUI, `overrideDevices = false`, nothing in git): reproducibility
    # won. What it does expose is a stable identity link and the device's announced
    # relay address; enable `options.announceLANAddresses = false` as well if that
    # matters more than pairing from a bare rebuild.
    #
    # ignorePatterns: Obsidian rewrites .obsidian/workspace*.json on every open
    # (window layout, open tabs), which is pure churn between two devices and the
    # one file that conflicts on each switch; .trash is Obsidian's own trash and
    # .stversions is the staggered versioner's output. ~/wiki is also a git repo,
    # so .git is kept on the host only -- the phone reads notes, and a synced
    # .git/index is a conflict waiting for the first commit on either side.
    settings = {
      devices.phone = {
        id = "QTQIILO-RJK6M6J-GMPDQ4A-3QLA7PZ-ONDHZ3G-CIGFS5S-U74KX43-EBJ4PQN";
        name = "chloe-phone_redmi-note-15-pro";
      };
      folders = {
        mind = {
          label = "Mind";
          path = "/home/chloe/Mind";
          # string form, not { name = "phone"; }: with the attrset form the
          # submodule always materialises `encryptionPasswordFile = null`, and
          # this pin's init script hashes it unconditionally
          # (`hashString "sha256" device.encryptionPasswordFile` in syncthing.nix:216)
          # -> "expected a string but found null" at whole-system evaluation.
          devices = [ "phone" ];
          ignorePatterns = [
            ".obsidian/workspace*.json"
            ".trash"
            ".stversions"
          ];
          # A thumb that deletes a note would otherwise propagate; the staggered
          # versioner keeps 30 days of superseded files on the host.
          versioning = {
            type = "staggered";
            params = {
              cleanInterval = "3600";
              maxAge = "2592000";
            };
          };
        };
        wiki = {
          label = "wiki";
          path = "/home/chloe/wiki";
          # string form, not { name = "phone"; }: with the attrset form the
          # submodule always materialises `encryptionPasswordFile = null`, and
          # this pin's init script hashes it unconditionally
          # (`hashString "sha256" device.encryptionPasswordFile` in syncthing.nix:216)
          # -> "expected a string but found null" at whole-system evaluation.
          devices = [ "phone" ];
          ignorePatterns = [
            ".obsidian/workspace*.json"
            ".trash"
            ".stversions"
            ".git"
          ];
          versioning = {
            type = "staggered";
            params = {
              cleanInterval = "3600";
              maxAge = "2592000";
            };
          };
        };
      };
    };
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

  # ── Hermes dashboard: the backend Herald / Desktop attach to ────────────
  # Added 2026-10-29. The phone client (Herald, an unofficial Android client)
  # and Hermes Desktop's "Remote gateway" both speak to `hermes dashboard` --
  # NOT to the messaging gateway in hermes-agent.service -- and a dashboard
  # that is not running means "connection refused" no matter how good the
  # tailnet is. Started by hand it dies with the shell, so it belongs in a
  # unit here and comes up on boot.
  #
  # A non-loopback bind engages the dashboard's auth gate and Hermes fails
  # closed without a provider, so the unit loads the bundled username/password
  # provider from a runtime file instead of config.yaml: config.yaml in the
  # state dir is rewritten from modules/config/hermes/config.yaml on every
  # activation, so dashboard edits made through the UI (or by hand) are lost
  # there. The credentials file holds the scrypt-hashed password and the
  # session-signing secret -- neither belongs in this repository:
  #   /var/lib/hermes/.hermes/dashboard-auth.env  (0600 chloe, prefix-less keys)
  #     HERMES_DASHBOARD_BASIC_AUTH_USERNAME / _PASSWORD / _SECRET
  #
  # Bound to the tailnet address only, matching the URL the phone signs in to
  # (http://100.73.119.21:9119): nothing is exposed on wlo1, and the firewall
  # above trusts tailscale0 only, so the tailnet is the whole access story.
  #
  # RestartPreventExitStatus=78 -- exit 78 is Hermes's deliberate refusal when
  # another dashboard already owns the host; parking on it beats a restart
  # loop. --skip-build serves the prebuilt SPA from the store, so boot never
  # needs npm.
  systemd.services.hermes-dashboard = {
    description = "Hermes dashboard (remote gateway for phone and desktop)";
    wantedBy = [ "multi-user.target" ];
    wants = [ "tailscaled.service" ];
    after = [ "tailscaled.service" "network-online.target" "hermes-agent.service" ];
    serviceConfig = {
      User = "chloe";
      Group = "hermes";
      WorkingDirectory = "/home/chloe";
      Environment = [
        "HERMES_HOME=/var/lib/hermes/.hermes"
        "HOME=/var/lib/hermes"
      ];
      EnvironmentFile = "/var/lib/hermes/.hermes/dashboard-auth.env";
      ExecStart = "${config.services.hermes-agent.package}/bin/hermes dashboard --host 100.73.119.21 --port 9119 --no-open --skip-build";
      Restart = "always";
      RestartSec = 10;
      RestartPreventExitStatus = 78;
      UMask = "0007";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/var/lib/hermes" "/home/chloe" ];
    };
  };
}
