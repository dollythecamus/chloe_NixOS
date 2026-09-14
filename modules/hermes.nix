{config, pkgs, lib, inputs, ... }:

{
    # SearXNG — self-hosted search engine
      # used by hermesn
    imports = [ 
      #./searxng.nix 
    ];

    services.hermes-agent = {
    enable = true;
    # container = {enable = true; hostUsers = ["chloe"];};

    extraDependencyGroups = ["messaging" "hindsight" "anthropic"];
    # messaging  = discord
    # hindsight  = memory provider

    configFile = ./config/hermes/config.yaml;

    # Path to the environment files containing API tokens/keys
    environmentFiles = [ 
        config.age.secrets.hermes-env.path
    ];
    
    # links the 'hermes' CLI tool to system packages
    addToSystemPackages = true;
  };

  # ── Interactive users share the gateway's state store ────────────────────
  # The upstream module only creates a ~/.hermes -> /var/lib/hermes/.hermes
  # symlink bridge for container-mode hostUsers; in native mode it relies on
  # HERMES_HOME being exported into every interactive shell. Shells launched
  # without it (sudo-ed env, GUI launchers) silently fall back to $HOME/.hermes
  # and create a SECOND, empty brain — no memory, no skills, no history, and
  # repeated "run hermes setup again" prompts. This is that missing bridge.
  # Run hermes as chloe (member of the hermes group), NOT via sudo: root-owned
  # files with umask 022 break the gateway's group write access.
  system.activationScripts."hermes-user-bridge" = lib.stringAfter [ "hermes-agent-setup" ] ''
    for _t in "chloe:/home/chloe" "root:/root"; do
      _u="''${_t%%:*}"; _h="''${_t##*:}"
      if [ -d "$_h/.hermes" ] && [ ! -L "$_h/.hermes" ]; then
        _b="$_h/.hermes.bak.$(date +%Y%m%d_%H%M%S)"
        echo "hermes-user-bridge: real dir at $_h/.hermes -> backing up to $_b"
        mv "$_h/.hermes" "$_b"
      fi
      ln -sfn /var/lib/hermes/.hermes "$_h/.hermes"
      chown -h "$_u":hermes "$_h/.hermes" 2>/dev/null || true
    done

    # ── Shared-state permissions ────────────────────────────────────────────
    # The gateway (user hermes) writes credentials/caches 0600/0640 and some
    # files end up root- or chloe-owned 0600; chloe's TUI hits EACCES on those
    # ("/var/lib/hermes/.hermes/... Permission denied", auth.json spams every
    # turn). Upstream already runs the unit with UMask=0007 and makes the state
    # dirs setgid 2770, so this pass just completes the group-sharing layout on
    # every activation: everything hermes:hermes, dirs 2770, files 0660,
    # secrets (.env) 0640 (group read, no write), auth.json explicitly 0660 —
    # hermes rewrites it 0600 on 'hermes auth', so re-normalize here.
    if [ -d "/var/lib/hermes/.hermes" ]; then
      chown -R hermes:hermes /var/lib/hermes/.hermes
      find /var/lib/hermes/.hermes -type d -exec chmod 2770 {} +
      find /var/lib/hermes/.hermes -type f -exec chmod 0660 {} +
      chmod 0640 /var/lib/hermes/.hermes/.env
      chmod 0660 /var/lib/hermes/.hermes/auth.json
    fi
  '';

  # ── Runtime guard for the same permissions ───────────────────────────────
  # hermes 0.21.x tightens HERMES_HOME to 0700 every time it persists
  # credentials (agent/credential_pool.py -> hermes_cli.auth._save_auth_store
  # -> _write_private_file_atomic -> secure_parent_dir -> os.chmod(parent,0700)),
  # and rewrites auth.json 0600. The gateway runs as 'hermes', so that chmod
  # locks the interactive user (chloe, group hermes) out of the whole shared
  # state dir: TUI prompts die with "state.db is not writable ... is read-only
  # for this user", sessions/config/memory look empty, and the TUI's own
  # self-repair fails with EPERM. The activation pass above only runs at
  # switch/boot, so re-apply the same normalization on a short timer.
  systemd.services.hermes-state-perm-guard = {
    description = "Re-normalize Hermes shared state dir permissions (group access)";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "hermes-state-perm-guard" ''
        set -u
        SD=/var/lib/hermes/.hermes
        [ -d "$SD" ] || exit 0
        # The lockout case: the app chmods the top dir 0700 (owner-only).
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
    description = "Periodic Hermes state dir permission guard";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "30s";
      AccuracySec = "5s";
    };
  };
}
