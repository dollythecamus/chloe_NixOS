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
}
