{config, pkgs, lib, inputs, ... }:
{
    # SearXNG — self-hosted search engine
      # used by hermesn
    imports = [
      #./searxng.nix
    ];

    # createUser = false also disables the module's `users.groups.hermes = {}`
    # creation — without it the gateway unit fails at step GROUP ("Unknown
    # group"). The group is kept: it is wired into stateDir ownership modes and
    # chloe's extraGroups; we drop only the module-created SERVICE user.
    users.groups.hermes = { };

    services.hermes-agent = {
    enable = true;
    # container = {enable = true; hostUsers = ["chloe"];};

    # ── Single-owner state (fixes the recurring 0600/0700 EACCES lockout) ──
    # Hermes hardcodes owner-only chmods at runtime (auth.json 0600, state.db
    # chmod-by-owner via _secure_state_db_files, HERMES_HOME → 0700 on every
    # credential save). With the gateway on uid `hermes` and the TUI on uid
    # `chloe`, each side repeatedly locks the other out; a non-owner chmod is
    # EPERM regardless of group bits, so only the repair script (sudo) could
    # undo it. Running the gateway AS chloe collapses both into one owner:
    # 0600 files remain writable by both sides by construction. Tradeoff —
    # gateway-initiated turns (Discord, cron, webhooks) now run with chloe's
    # full privileges instead of a sandboxed system account. Chloe accepted
    # this (2026-09-23) over the container restructure and over a chmod timer.
    user = "chloe";
    group = "hermes";
    createUser = false;

    extraDependencyGroups = ["messaging" "anthropic"];
    # messaging  = discord
    # hindsight  = memory provider

    configFile = ./config/hermes/config.yaml;

    # ── Identity ─────────────────────────────────────────────────────────
    # Hermes reads SOUL.md from HERMES_HOME and nowhere else (agent/
    # prompt_builder.load_soul_md — identity slot #1), so it belongs in the
    # store, not in a working directory. The module installs this file at
    # every activation as a real file (install -o ${cfg.user} -g ${cfg.group}
    # -m 0640), which is what both the gateway and the interactive TUI read:
    # chloe's ~/.hermes is the symlink bridge to /var/lib/hermes/.hermes.
    # Editing the file on disk is therefore a runtime edit that the next
    # switch reverts — change it here.
    hermesHomeFiles = {
      "SOUL.md" = ./config/hermes/SOUL.md;

      # ── The `code` profile's identity ───────────────────────────────────
      # A profile has its own HERMES_HOME ($HERMES_HOME/profiles/<name>), and
      # Hermes reads that profile's SOUL.md from there — so the identity of
      # the coding profile is declared here for the same reason as the root
      # one. It is the same file Hermes would otherwise own at runtime; the
      # difference is that this one is recorded in git and survives a
      # re-clone of the profile.
      "profiles/code/SOUL.md" = ./config/hermes/SOUL-code.md;

      # ── The `nixos` profile's identity ──────────────────────────────────
      # Same mechanism, same reason: the NixOS configuration profile reads
      # its identity from profiles/nixos/SOUL.md, so it is declared here and
      # not left as a runtime edit.
      "profiles/nixos/SOUL.md" = ./config/hermes/SOUL-nixos.md;
    };

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
  # Run hermes NATIVELY as chloe (the gateway now runs as chloe too — see
  # above); do NOT run the TUI via sudo: root-owned files with umask 022
  # break group access and mask permission bugs.
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
  '';
}
