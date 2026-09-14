{config, pkgs, lib, inputs, ... }:

let
  # The interactive CLI must carry the same dependency groups as the gateway
  # package the module builds: anthropic = the API mode the configured model
  # uses, hindsight = memory provider, messaging = platform plugins. This is
  # the same expression as the module's effectivePackage, so it evaluates to
  # the same derivation.
  hermesCli = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    extraDependencyGroups = [ "messaging" "hindsight" "anthropic" ];
  };

  hermesHome = "/var/lib/hermes/.hermes";
in

{
    services.hermes-agent = {
    enable = true;

    extraDependencyGroups = ["messaging" "hindsight" "anthropic"];
    # messaging  = discord
    # hindsight  = memory provider

    configFile = ./config/hermes/config.yaml;

    # Path to the environment files containing API tokens/keys
    environmentFiles = [
        config.age.secrets.hermes-env.path
    ];

    # Deliberately NOT addToSystemPackages. That option exports HERMES_HOME
    # system-wide and forces every interactive shell into the gateway's store,
    # which hermes 0.21.x re-hardens to owner-only whenever it opens the store
    # for writing (hermes_state._secure_state_db_files -> chmod 0600 on
    # state.db/-wal/-shm; hermes_constants.secure_parent_dir -> chmod 0700 on
    # HERMES_HOME). Those calls are ownership operations: a second uid gets
    # EPERM/EACCES no matter how the group bits are set, so the TUI could not
    # open a session store at all and needed sudo. The CLI is added below
    # without the export instead, so it uses its own ~/.hermes.
    addToSystemPackages = false;
  };

  # The interactive CLI, PATH-only (no HERMES_HOME export).
  environment.systemPackages = [ hermesCli ];

  # ── Per-user Hermes homes ────────────────────────────────────────────────
  # Retires the shared-state bridge (~/.hermes -> /var/lib/hermes/.hermes) and
  # gives each user a real, private home of their own. The legacy symlink must
  # be removed explicitly — left in place it keeps redirecting the CLI into the
  # gateway's store, and files root writes there (0600 root) then break the
  # gateway's own opens.
  system.activationScripts."hermes-user-home" = lib.stringAfter [ "hermes-agent-setup" ] ''
    _h=/home/chloe
    if [ -L "$_h/.hermes" ] && [ "$(readlink "$_h/.hermes")" = "${hermesHome}" ]; then
      rm -f "$_h/.hermes"
      echo "hermes-user-home: removed shared-state symlink at $_h/.hermes"
    fi
    mkdir -p "$_h/.hermes"
    chown chloe:users "$_h/.hermes"
    chmod 0700 "$_h/.hermes"

    _h=/root
    if [ -L "$_h/.hermes" ] && [ "$(readlink "$_h/.hermes")" = "${hermesHome}" ]; then
      rm -f "$_h/.hermes"
      echo "hermes-user-home: removed shared-state symlink at $_h/.hermes"
    fi
    mkdir -p "$_h/.hermes/cache/terminal"
    chown -R root:root "$_h/.hermes"
    chmod 0700 "$_h/.hermes"

    # chloe's TUI needs the same provider keys the gateway uses. install, not
    # ln: the decrypted secret stays 0400 root, so root does the copy and chloe
    # reads the result. Refreshed at every activation, so a rekeyed secret
    # reaches the TUI at the next switch or boot.
    if [ -f "${config.age.secrets.hermes-env.path}" ]; then
      install -o chloe -g users -m 0600 "${config.age.secrets.hermes-env.path}" /home/chloe/.hermes/.env
    fi
  '';

  # ── Contamination guard for the gateway's store ──────────────────────────
  # The store now belongs to the hermes user alone. This only repairs ownership
  # and modes if something else writes there by accident (a stray root run, a
  # restored backup, an old shell that still has HERMES_HOME exported). A file
  # the gateway does not own makes its next open fail with EPERM
  # (_secure_state_db_files), and a mode-only fix cannot recover from that —
  # hence the chown.
  systemd.services.hermes-state-perm-guard = {
    description = "Re-normalize the Hermes gateway state dir (ownership + group access)";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "hermes-state-perm-guard" ''
        set -u
        SD=${hermesHome}
        [ -d "$SD" ] || exit 0
        chown hermes:hermes "$SD" 2>/dev/null || true
        chmod 2770 "$SD" 2>/dev/null || true
        # Anything the app (0600) or another uid left without group rw is
        # handed back to hermes:hermes with group access. No-op when already ok.
        find "$SD" -xdev -type d ! -perm 2770 -exec chown hermes:hermes {} + -exec chmod 2770 {} + 2>/dev/null || true
        find "$SD" -xdev -type f ! -perm 0660 -exec chown hermes:hermes {} + -exec chmod 0660 {} + 2>/dev/null || true
        chmod 0640 "$SD/.env" 2>/dev/null || true
      '';
    };
  };

  systemd.timers.hermes-state-perm-guard = {
    description = "Periodic Hermes gateway state dir guard";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "30s";
      AccuracySec = "5s";
    };
  };
}
