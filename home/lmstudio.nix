# Headless LM Studio endpoint for Hermes/pi: the `llmster` daemon plus the
# OpenAI-compatible API server on 127.0.0.1:1234, as a user unit that comes up
# at login. The GUI (system package `lmstudio`) keeps working on its own and
# shares the same ~/.lmstudio model store, so a model downloaded in the GUI is
# immediately servable here.
#
# 2026-11-08 — four things measured on this host, all load-bearing
# (full write-up: ~/projects/agent-builds/local-triage/NOTES-lms.md):
#
#  * `lms server start` does NOT start the daemon. Against no daemon it dies
#    with "Timed out waiting for LM Studio daemon to start", which is also why
#    the upstream flake's own unit (ExecStart = lms server start) cannot work
#    here. The daemon is `llmster`.
#  * The CLI must not run before this daemon has minted its passkey — see the
#    comment on `launch`; getting that wrong was a permanent failure.
#  * XDG_DATA_DIRS must include /run/opengl-driver/share. Without it the bundled
#    Vulkan hardware survey times out after 5000 ms and the daemon aborts with a
#    misleading "You must call loadLib before using getLib".
#  * LD_LIBRARY_PATH needs libgcc. The CUDA engine is downloaded into
#    ~/.lmstudio/extensions/backends/ at runtime, so it never goes through
#    autoPatchelf and cannot find libgomp.so.1 by itself.
#
# Switching the system is not enough to pick up a change to THIS unit:
# home-manager relinked the file ~1 s AFTER restarting the unit, so systemd came
# up with the previous definition (start-post, two daemons, no port). After any
# switch that touches this file: `systemctl --user daemon-reload` then
# `systemctl --user restart lmstudio`.
{ pkgs, inputs, lib, ... }:

let
  pkg = inputs.lmstudio.packages.${pkgs.stdenv.hostPlatform.system}.lmstudio-server;

  # One place to change if the GUI should keep 1234 and this should move
  # (Hermes' lmstudio provider honours LM_BASE_URL, so a port change here is
  # paired with LM_BASE_URL=http://127.0.0.1:<port>/v1 on the agent side).
  port = 1234;

  # One script, because the CLI must not run before the daemon has minted its
  # passkey: llmster writes ~/.lmstudio/.internal/lms-key-2 at startup and
  # authenticates the CLI against it. A CLI that arrives first mints its own
  # key, is rejected ("Invalid passkey for lms CLI client"), and then spawns a
  # second daemon that rotates the key again — a hole it never climbs out of.
  # The first version of this unit polled `lms server start` from t=0 via
  # ExecStartPost and failed on exactly that. So: start the daemon, gate on its
  # key, then open the port.
  launch = pkgs.writeShellScript "lmstudio-daemon" ''
    export PATH=${lib.makeBinPath [ pkgs.coreutils ]}:$PATH
    # Keep whatever the session exported, then add what is missing.
    export XDG_DATA_DIRS="/run/opengl-driver/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
    export LD_LIBRARY_PATH="${lib.makeLibraryPath [ pkgs.libgcc.lib pkgs.vulkan-loader ]}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    key="$HOME/.lmstudio/.internal/lms-key-2"
    started=$(date +%s)

    ${pkg}/bin/llmster &
    dpid=$!

    # Readiness gate: wait until THIS daemon has written a key minted after it
    # started (a stale key from a previous run must not pass).
    waited=0
    while [ ! -f "$key" ] || [ "$(stat -c %Y "$key" 2>/dev/null || echo 0)" -lt "$started" ]; do
      kill -0 "$dpid" 2>/dev/null || exit 1
      sleep 1
      waited=$((waited + 1))
      [ "$waited" -ge 120 ] && break
    done
    sleep 2

    # Now the CLI shares the daemon's passkey and can open the port.
    for _ in $(seq 1 30); do
      ${pkg}/bin/lms server start --port ${toString port} >/dev/null 2>&1 && break
      sleep 2
    done

    # Stay as the unit's main process for as long as the daemon lives.
    wait "$dpid"
  '';
in
{
  systemd.user.services.lmstudio = {
    Unit = {
      Description = "LM Studio daemon + API server (:${toString port})";
      After = [ "default.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${launch}";
      # "-" = ignore failure: the daemon may already be gone and there is
      # nothing left to stop.
      ExecStopPost = "-${pkg}/bin/lms server stop";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStartSec = 300;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
