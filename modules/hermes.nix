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

    # ── OCI container mode (2026-10-24) ──────────────────────────────────
    # Hermes runs from the sealed nix package bind-mounted read-only into a
    # plain Ubuntu container, with /var/lib/hermes mounted at /data and
    # /var/lib/hermes/home at /home/hermes. The point is self-modification:
    # inside the container the agent has a writable apt/pip/npm layer and a
    # real root, instead of the read-only nix store it lives in natively.
    #
    # Everything the host CLI does now goes through `docker exec`
    # (hermes_cli/main_container.py reads .container-mode, which activation
    # writes): `hermes`, `hermes --tui`, `hermes -p <profile>`, `hermes serve`.
    # The Desktop app is a host Electron process that talks to the gateway over
    # HERMES_HOME/gateway.sock, so it keeps working as long as the gateway runs
    # as uid 1000 — which it does (see the exec_user hook below).
    #
    # hostUsers = [ "chloe" ] gives upstream's ~/.hermes symlink bridge and the
    # hermes group membership; addToSystemPackages (below) is what puts a host
    # `hermes` binary on PATH for the router to start from.
    #
    # Mounts, each with a reason — the container otherwise sees only /data and
    # /nix/store, which silently breaks things the config.yaml already points at:
    #  * /home/chloe  → ~/projects, ~/nixos, ~/Mind at their real paths (the
    #    godot MCP pins GODOT_MCP_PROJECT_PATH=/home/chloe/projects/...), and
    #    the same filesystem access the native service had (ProtectHome=false).
    #  * /run/current-system + /etc/static → the system-profile tools the config
    #    names by absolute path: npx (godot MCP) and piper (TTS). A bind mount is
    #    re-resolved on every `docker start`, so a rebuild that restarts this
    #    unit picks up the new generation. If a `nix-collect-garbage -d` ever
    #    deletes the generation the container started on, those two tools point
    #    at a missing store path until `systemctl restart hermes-agent`.
    #  * /etc/hermes → the Piper voice (a symlink into /etc/static, hence both).
    # Deliberately NOT mounted: /run/user/1000 and the session bus. computer_use
    # needs them, but the GNOME adapter already refuses on this host (driver
    # 0.28.1, owner-proof failure) and portal screenshots only — so the tool
    # degrades to "driver unavailable" in the container instead of being wired
    # to a bus it cannot reach. See the CUA env block below for the native path.
    container = {
      enable = true;
      backend = "docker";
      image = "ubuntu:24.04";
      hostUsers = [ "chloe" ];
      extraVolumes = [
        "/home/chloe:/home/chloe:rw"
        "/run/current-system:/run/current-system:ro"
        "/etc/static:/etc/static:ro"
        "/etc/hermes:/etc/hermes:ro"
      ];
      # `hermes` is `docker exec`'d without -w, so without this every session
      # starts in the image's "/" and project context (AGENTS.md, git) is lost.
      # --init: the entrypoint `exec`s the gateway as the container's PID 1, and
      # Hermes warns (and leaks zombies) when it is PID 1 with no init above it —
      # tini reaps the tool subprocesses the gateway spawns and forwards SIGTERM
      # on `docker stop`.
      extraOptions = [ "--init" "--workdir" "/home/chloe" ];
    };

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
    # 2026-10-24: the container migration did NOT change this. The gateway now
    # runs as uid 1000 inside the container, which is the same uid, and
    # gateway_runtime_discovery requires the control socket's owner to equal the
    # caller's uid — a system uid `hermes` would make Desktop refuse to connect.
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
  # NATIVE MODE ONLY (container.enable = false). In container mode this
  # environment lands on the `docker start` process, not inside the container,
  # and the driver/bus/wayland sockets are not mounted there — computer_use
  # reports "driver unavailable" instead. Kept as the rollback path.
  #
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
  # Upstream's container branch owns the ~/.hermes -> /var/lib/hermes/.hermes
  # symlink bridge now (container.hostUsers = [ "chloe" ] above), and it also
  # backs up a real directory before replacing it — so the local loop that used
  # to do this for chloe AND root is gone. Root's bridge went with it: `sudo
  # hermes` is not a supported path (root-owned 022 files break the state dir),
  # and /root/.hermes did not exist as a real directory anyway.
  #
  # ── Container-mode host wiring (2026-10-24) ─────────────────────────────
  # Three hooks the upstream module cannot know about. The first two are
  # activation scripts ordered after its own hermes-agent-setup (which writes
  # .container-mode on every switch); the third extends systemd's preStart.

  # 1. exec_user must be numeric. The entrypoint reuses whatever account owns
  #    uid 1000 in the image — in ubuntu:24.04 that is `ubuntu`, and no `chloe`
  #    user is ever created — so the router's `docker exec -u chloe` dies with
  #    "unable to find user chloe" and every CLI invocation fails. `docker exec
  #    -u 1000` works against any image.
  #
  #    BASH BUILTINS ONLY. The activation PATH is coreutils + gnugrep + findutils
  #    + shadow + util-linux — there is no `sed` and no `awk`. The first version
  #    of this hook used `sed ... > $_tmp`; sed exited 127, the redirect left an
  #    EMPTY temp file, `install` copied it over .container-mode, the router read
  #    an empty file and fell back to its built-in default exec_user=hermes, and
  #    every `hermes` invocation failed with "unable to find user hermes: no
  #    matching entries in passwd file" (verified 2026-10-24). The grep below is
  #    the guard that makes such a silent corruption loud.
  system.activationScripts."hermes-container-exec-user" = lib.stringAfter [ "hermes-agent-setup" ] ''
    _cm=${hermesHome}/.container-mode
    if [ -f "$_cm" ]; then
      _uid=$(id -u chloe)
      _tmp="$_cm.new"
      while IFS= read -r _line || [ -n "$_line" ]; do
        case "$_line" in
          exec_user=*) printf 'exec_user=%s\n' "$_uid" ;;
          *) printf '%s\n' "$_line" ;;
        esac
      done < "$_cm" > "$_tmp"
      install -o chloe -g hermes -m 0644 "$_tmp" "$_cm"
      rm -f "$_tmp"
      if ! grep -q "^exec_user=$_uid$" "$_cm"; then
        echo "hermes-container-exec-user: FAILED — $_cm does not carry exec_user=$_uid;" \
             "the host CLI/TUI will not route into the container" >&2
      fi
    fi
  '';

  # 2. A container whose first-boot apt provisioning was interrupted must be
  #    discarded, not restarted. Upstream's entrypoint installs sudo/curl/node
  #    into the container's writable layer on first boot; if the container is
  #    stopped while apt is unpacking (unit restart, docker daemon restart, an
  #    aborted rebuild — this happened on 2026-10-24 at 19:19:20, 27s into the
  #    first boot), dpkg is left half-configured and every later start dies in
  #    ~2s with "E: dpkg was interrupted" (exit 100), which cannot be repaired
  #    from outside that layer. Upstream's preStart only recreates on an identity
  #    change, so the layer stays bricked forever. This runs BEFORE it (mkBefore):
  #    stopped + no provisioning sentinel ⇒ discard the layer, and preStart then
  #    creates a clean one. A provisioned container is never touched, so the
  #    agent's own apt/pip/npm installs survive ordinary restarts.
  systemd.services.hermes-agent.preStart = lib.mkBefore ''
    if ${pkgs.docker}/bin/docker inspect hermes-agent >/dev/null 2>&1; then
      _h_running=$(${pkgs.docker}/bin/docker inspect -f '{{.State.Running}}' hermes-agent 2>/dev/null || echo false)
      if [ "$_h_running" != "true" ] \
         && ! ${pkgs.docker}/bin/docker cp hermes-agent:/var/lib/hermes-tools-provisioned - >/dev/null 2>&1; then
        echo "hermes-agent: tool provisioning never completed — discarding the half-configured container layer"
        ${pkgs.docker}/bin/docker rm -f hermes-agent || true
      fi
    fi
  '';

  # 2. Cleanup of what the native install leaves lying around, evaluated
  #    statelessly on every activation instead of behind a marker file. The
  #    failure it prevents: a stale gateway.sock/pid/lock from the native gateway
  #    (or from an unclean container shutdown) making the container's
  #    `gateway run --replace` refuse to start, or pointing every Desktop/CLI
  #    connection at a dead socket. Rule: clean only while the container is NOT
  #    running, because then nothing owns those files — this also covers boot
  #    (activation runs before services, so a socket from the previous session is
  #    always stale) while a switch taken while the container runs leaves the
  #    live socket alone.
  system.activationScripts."hermes-container-cleanup" = lib.stringAfter [ "hermes-agent-setup" ] ''
    if ! ${pkgs.docker}/bin/docker inspect -f '{{.State.Running}}' hermes-agent 2>/dev/null | grep -qx true; then
      rm -f ${hermesHome}/gateway.sock ${hermesHome}/gateway.pid ${hermesHome}/gateway.lock
    fi
    # Any container from an earlier manual attempt holding the same state mount
    # would fight this one for the gateway socket. hermes-agent itself is never
    # touched here.
    for _c in $(${pkgs.docker}/bin/docker ps -a --format '{{.Names}}' | grep -E '^hermes' || true); do
      if [ "$_c" != "hermes-agent" ]; then
        echo "hermes-container-cleanup: removing stale container $_c"
        ${pkgs.docker}/bin/docker rm -f "$_c" || true
      fi
    done
  '';
}
