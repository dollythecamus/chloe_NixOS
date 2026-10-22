{config, pkgs, lib, inputs, ... }:
let
  # HERMES_HOME exactly as the upstream module derives it (stateDir + /.hermes).
  # Used only by the permission block below; stateDir has a plain default, so
  # reading it here is not recursive.
  hermesHome = "${config.services.hermes-agent.stateDir}/.hermes";

  # Local Piper voice (en_US-amy-medium, 63 MB) fetched at build time and
  # installed read-only under /etc/hermes/piper. Edge TTS is unusable here:
  # Microsoft's endpoint rejects the websocket handshake with 403 (verified
  # 2026-10-21), so TTS uses the local Piper CLI via a command provider.
  piperVoice = pkgs.fetchurl {
    url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx";
    sha256 = "sha256-s6bke1e4x/vmoM4lGBYaUPWanN2KUINcAssCvdYgbBg=";
  };
  piperVoiceConfig = pkgs.fetchurl {
    url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx.json";
    sha256 = "sha256-laI+tNQpCdON9zu5rH9F9Zfb/N4tG/lSb96vVGaXfXc=";
  };
in
{
    imports = [
    ];

    # Piper CLI for the `tts` toolset's command provider. The binary is not on
    # the gateway unit's PATH, so config.yaml calls it by absolute path.
    environment.systemPackages = [ pkgs.piper-tts ];
    environment.etc = {
      "hermes/piper/en_US-amy-medium.onnx".source = piperVoice;
      "hermes/piper/en_US-amy-medium.onnx.json".source = piperVoiceConfig;
    };

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
    # Local speech-to-text and local Lightpanda browser runtime. Keep these in
    # the Hermes service closure/PATH as well as the system profile so gateway
    # turns do not depend on an interactive shell's environment.
    extraPackages = [
      (pkgs.callPackage ../pkgs/lightpanda.nix { })
      inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.agent-browser
      # cua-driver calls `gdbus` by name to reach the WinRects GNOME helper
      # (org.cua.WinRects). The unit PATH is a fixed store list that does not
      # include /run/current-system/sw/bin, so without this the adapter probe
      # fails even when the extension is active.
      pkgs.glib.bin
    ];
    # messaging = Discord; Holographic memory is bundled and uses local SQLite.
    # numpy is NOT in the sealed venv: the holographic memory plugin moved out of
    # core into the community catalog (cloned pinned copy at
    # /var/lib/hermes/.hermes/plugins/holographic, v0.6.1 — PM install is broken
    # on the sealed layout, missing uv.lock). Without numpy the plugin self-reports
    # fact_store stats structural_recall: "off (numpy missing)" — keyword recall
    # works, HRR structural related/reason recall degraded. numpy's interpreter
    # MUST come from the plugin lockfile's interpreter (package.python.pkgs), not a
    # nixpkgs python-set: the lockfile pins the version. Evidence + steps:
    # docs/holographic-numpy-handoff.md (2026-10-12).
    extraPythonPackages = [
      config.services.hermes-agent.package.python.pkgs.numpy
      (pkgs.callPackage ../pkgs/hermes-faster-whisper.nix {
        python = config.services.hermes-agent.package.python;
      })
    ];

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

      # The nixos profile keeps its existing model/tool preferences, with the
      # memory provider managed declaratively alongside them. This full config
      # is installed on activation; edit the source, not the profile copy.
      "profiles/nixos/config.yaml" = ./config/hermes/config-nixos.yaml;

      # ── The `nixos` profile's identity ──────────────────────────────────
      # Same mechanism, same reason: the NixOS configuration profile reads
      # its SOUL.md from profiles/nixos/SOUL.md, so it is declared here and
      # not left as a runtime edit.
      "profiles/nixos/SOUL.md" = ./config/hermes/SOUL-nixos.md;

      # ── The `learn` profile's identity ──────────────────────────────────
      # The hobby-learning profile (drawing/painting, animation, music —
      # composition, guitar, singing). Same mechanism and same reason as the
      # others: the profile reads its SOUL.md from its own HERMES_HOME, so the
      # identity is recorded in git instead of living as a runtime edit that
      # no repository can restore. Its skills live under the profile's own
      # skills/ directory as runtime state.
      "profiles/learn/SOUL.md" = ./config/hermes/SOUL-learn.md;
    };

    # Path to the environment files containing API tokens/keys
    environmentFiles = [
        config.age.secrets.hermes-env.path
    ];

    # links the 'hermes' CLI tool to system packages
    addToSystemPackages = true;
  };

  # ── HERMES_HOME must not stay group-writable ─────────────────────────────
  # hermes_cli/gateway_runtime_discovery.home_mode_unsafe() refuses a HERMES_HOME
  # that is group-writable unless the group is the owner's own PRIVATE group
  # (gr_name == pw_name, gid == the user's primary gid). Our group is `hermes`,
  # so the upstream module's 2770 — its `d` tmpfiles rule plus the
  # `chmod 2770` inside activationScripts."hermes-agent-setup" — makes every
  # Desktop/TUI connection fail after a reboot with:
  #   Gateway inaccessible (unsafe_control_permissions).
  #   /var/lib/hermes/.hermes has mode 2770, writable by another user;
  #   chmod go-w /var/lib/hermes/.hermes
  # (seen in the desktop log at 09:02 on 2026-10-21, fixed by hand, back on the
  # next boot). Under single-owner state the gateway IS chloe, so group write
  # buys nothing — there is no second uid to use it. Drop g+w and keep setgid so
  # files created inside still land in group `hermes` (0640/0660 stays readable).
  # Two hooks because the 2770 arrives from two independent places:
  #  * tmpfiles: a `z` line in its own 90-* file. Rules are processed in file
  #    order, so this runs after 00-nixos.conf's `d` line; `z` only adjusts an
  #    existing path's mode (no create, no chown) — verified with
  #    `systemd-tmpfiles --create` across two config files → 2750.
  #  * activation: a script ordered after `hermes-agent-setup`, which is what
  #    re-applies 2770 on every `nixos-rebuild switch`.
  environment.etc."tmpfiles.d/90-hermes-home-mode.conf".text = ''
    z ${hermesHome} 2750 - - - -
  '';

  system.activationScripts."hermes-home-mode" = lib.stringAfter [ "hermes-agent-setup" ] ''
    chmod 2750 ${hermesHome}
  '';

  # ── Gateway environment for computer_use ────────────────────────────────
  # The driver is packaged by modules/cua-driver.nix, but the gateway unit's
  # PATH is a fixed store list without /run/current-system/sw/bin, and its
  # environment has no graphical-session variables. The computer_use resolver
  # only honours HERMES_CUA_DRIVER_CMD (or a pm-installed package), so the path
  # must be explicit. WAYLAND_* reaches niri-native windows; DISPLAY is the
  # XWayland fallback.
  #
  # computer_use is enabled for CLI/desktop and Discord, and deliberately NOT
  # for cron: platform_toolsets.cron in config.yaml omits it. The socket name
  # (wayland-0) and uid (1000) are this host's values as of 2026-10-21.
  systemd.services.hermes-agent.environment = {
    HERMES_CUA_DRIVER_CMD = "/run/current-system/sw/bin/cua-driver";
    CUA_DRIVER_RS_ENABLE_WAYLAND = "1";
    XDG_RUNTIME_DIR = "/run/user/1000";
    WAYLAND_DISPLAY = "wayland-0";
    DISPLAY = ":0";
    # The cua-driver MCP server is a child of this unit. It reaches the
    # WinRects GNOME helper over the session bus with `gdbus`; without the bus
    # address and desktop identity the adapter probe fails even when the
    # extension is active. gdbus itself comes from pkgs.glib.bin in
    # extraPackages.
    DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "GNOME";
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
