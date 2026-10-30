{ config, pkgs, lib, ... }:

# Hermes Desktop launcher — hardware-safe flags (2026-10-29)
#
# Two problems the stock launcher has on this laptop, both visible as "the app
# stutters" and "the app eats a lot of RAM":
#
#   1. Sticky SwiftShader. `electron/linux-nvidia-egl-fallback.ts` records a GPU
#      process death in `nvidia-egl-fallback.json` and from then on routes ANGLE
#      through SwiftShader (`--use-angle=swiftshader`), i.e. every frame rastered
#      on the CPU. It re-probes hardware only when the app version OR the driver
#      version changes, and the Nix package version is frozen at 0.0.0, so one
#      crash pins the app to software rendering for good. Measured here on
#      2026-10-29: a 520 %-CPU GPU process and an unusable UI.
#      HERMES_DESKTOP_NVIDIA_SWIFTSHADER=0 is the documented opt-out
#      (`decideNvidiaEglFallback` returns enable=false for it); the generic Linux
#      path then falls back to `--disable-gpu` instead — still software, but
#      without a 500 %-CPU process.
#
#   2. A supervisor copy per launch. `wslgLaunchArgs()` runs before app-ready: on
#      a Wayland session whose argv has no explicit `--ozone-platform` it
#      re-execs the whole app with one appended (`electron/wslg-launch-process.ts`)
#      and the original process stays alive as its parent, carrying its own
#      network service and GPU process — ~310 MB here for a window it does not
#      own. Passing `--ozone-platform=wayland` up front makes that helper return
#      null, so exactly one browser process starts. It has to reach argv, which
#      is why it cannot be an extraEnv-style tweak on the package.
#
# Why the package wrapper is not edited instead: `nix/homeManagerModules.nix`
# builds the desktop package as `<package>.override { extraEnv = …; extraRun = …; }`
# with its own HERMES_HOME/HERMES_MANAGED values, and `nix/desktop.nix` does
# `defaults // extraEnv` — so anything this tree put into extraEnv/extraRun is
# replaced wholesale. A launcher script plus a desktop-entry override is the
# composition-safe layer.
#
# The app is started from the GNOME app grid, i.e. through
# `~/.local/share/applications/com.nousresearch.hermes.desktop`. Writing that
# file by hand (and not via `xdg.desktopEntries`, whose submodule trips the
# removed-`extraConfig` assertion on this pin) replaces the package's copy by
# desktop id, because XDG_DATA_HOME outranks the profile — one Hermes icon, not
# two. Terminal launches of `hermes-desktop` keep the stock behaviour.

let
  desktop = config.programs.hermes-agent.desktop.package;
  hermesDesktop = lib.getExe' desktop "hermes-desktop";

  launch = pkgs.writeShellScript "hermes-desktop-launch" ''
    set -eu
    export HERMES_DESKTOP_NVIDIA_SWIFTSHADER=0
    if [ "''${XDG_SESSION_TYPE:-}" = wayland ] || [ -n "''${WAYLAND_DISPLAY:-}" ]; then
      exec ${hermesDesktop} --ozone-platform=wayland "$@"
    fi
    exec ${hermesDesktop} "$@"
  '';
in
{
  xdg.dataFile."applications/com.nousresearch.hermes.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Hermes
    GenericName=Hermes Desktop
    Comment=Launch Hermes Desktop
    Exec=${launch}
    Icon=${desktop}/share/icons/hicolor/1024x1024/apps/hermes.png
    Terminal=false
    Categories=Utility;
    StartupNotify=true
    StartupWMClass=com.nousresearch.hermes
  '';
}
