# cua-driver — the background computer-use driver behind Hermes' `computer_use`
# toolset (https://github.com/trycua/cua).
#
# Why a derivation instead of the upstream installer: the released artifact is a
# generic glibc binary. `hermes computer-use install` drops it in ~/.local/bin,
# but it cannot run on this system — programs.nix-ld is disabled, so
# /lib64/ld-linux-x86-64.so.2 is NixOS's stub-ld placeholder and exec fails with
# "NixOS cannot run dynamically linked executables intended for generic linux
# environments". autoPatchelfHook rewrites the interpreter and RPATH to nix
# store libraries, which keeps the driver declarative and GC-safe.
#
# Upgrade procedure: bump `version`, then take the new sha256 from the release's
# release-manifest.json (asset `cua-driver-rs-<version>-linux-x86_64-binary.tar.gz`)
# and paste it into `hash`. Verify with `nix build` + `cua-driver --version`.
#
# Runtime notes (niri / Wayland):
# - The driver is driven by Hermes over stdio MCP; nothing here needs a daemon.
# - modules/cua-driver.nix sets CUA_DRIVER_RS_ENABLE_WAYLAND=1, which switches the
#   driver from the XWayland-only view to niri's wlroots globals (foreign-toplevel
#   discovery, screencopy capture, virtual pointer/keyboard).
{ lib
, pkgs
, stdenv
, fetchurl
, autoPatchelfHook
, libxkbcommon
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "cua-driver";
  version = "0.28.1";

  src = fetchurl {
    url = "https://github.com/trycua/cua/releases/download/cua-driver-rs-v${finalAttrs.version}/cua-driver-rs-${finalAttrs.version}-linux-x86_64-binary.tar.gz";
    hash = "sha256-caqSUz3pCmigoq+TAkPxdw0j5FuJa1fWehdj2kv66vc=";
  };

  # The tarball has no top-level directory.
  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];

  # libX11/libXi/libxkbcommon are what `cua-driver` actually links against;
  # the remaining X libraries are the ones the AT-SPI/XTest paths reach for.
  buildInputs = [
    pkgs.libx11
    pkgs.libxi
    pkgs.libxtst
    pkgs.libxext
    pkgs.libxrandr
    pkgs.libxfixes
    libxkbcommon
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;
  # Stripping would invalidate the release binary's own self-checks.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    # Keep the release layout intact — the driver resolves libcua_driver_sdk.so,
    # the Node runtime and the cursor theme relative to its own location.
    mkdir -p $out/libexec/cua-driver $out/bin
    cp -r ./. $out/libexec/cua-driver/
    ln -s $out/libexec/cua-driver/cua-driver $out/bin/cua-driver

    runHook postInstall
  '';

  meta = {
    description = "Background computer-use driver (prebuilt trycua/cua release, patched for NixOS)";
    homepage = "https://github.com/trycua/cua";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "cua-driver";
  };
})
