{
  config,
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}:

let
  # Creality Print 7 — Creality's official slicer (Orca/Bambu Studio lineage).
  #
  # Upstream (github.com/CrealityOfficial/CrealityPrint) ships Linux only as
  # an AppImage (plus a Flatpak bundle); there is no nixpkgs attr. The vendor
  # release tag is v7.2.1 — the 7.2.2 assets in that same release are
  # Windows/macOS only. Wrapped declaratively with appimageTools, the same
  # approach nixpkgs takes for cura-appimage (also used below for the icon).
  #
  # Note: CrealityPrint-7.2.1.5476 uses a monolithic static-Qt build but still
  # dlopens the system GTK/GL/WebKit stack (loads xcb/GLX/EGL at startup).
  pname = "crealityprint";
  version = "7.2.1.5476";

  src = pkgs.fetchurl {
    url = "https://github.com/CrealityOfficial/CrealityPrint/releases/download/v7.2.1/CrealityPrint-V${version}-x86_64-Release.AppImage";
    hash = "sha256-so9mwl0MZlLtauSdB2Z4D0aluDm5POGWjmOYI+H24vM=";
  };

  appimageContents = pkgs.appimageTools.extract { inherit pname version src; };

  crealityprint = pkgs.appimageTools.wrapType2 {
    inherit pname version src;
    # The AppImage's own AppRun adds its bundled runtime libs (bin/, usr/lib/).
    # The default FHS rootfs of appimageTools lacks the system libs the binary
    # NEEDs, so add them explicitly (verified against `patchelf --print-needed`).
    extraPkgs = p: with p; [
      webkitgtk_4_1 # libwebkit2gtk-4.1 + libjavascriptcoregtk-4.1 (Creality Cloud views)
      libsoup_3 # libsoup-3.0 (webkit dep)
      libdeflate # libdeflate.so.0
      zstd # libzstd.so.1
      gcc-unwrapped.lib # libstdc++.so.6 + libatomic.so.1
      libxkbcommon # libxkbcommon.so.0 (xcb platform plugin key handling)
      libGL # libGL.so.1 / libEGL.so.1 / libGLX.so.0 (via libglvnd)
    ];
    meta = {
      description = "Creality Print 3D slicer (Creality's official slicing software)";
      homepage = "https://github.com/CrealityOfficial/CrealityPrint";
      license = lib.licenses.unfree; # proprietary, binary-only upstream
      platforms = [ "x86_64-linux" ];
      mainProgram = "crealityprint";
    };
  };
in
{
  home.packages = [ crealityprint ];

  # Upstream's desktop file inside the AppImage points at `AppRun`; recreate it
  # so the entry resolves the wrapper in $out/bin (`crealityprint %F` opens
  # .stl/.obj/.3mf directly).
  xdg.desktopEntries.crealityprint = {
    name = "CrealityPrint";
    genericName = "3D Printing Software";
    comment = "Creality Print 3D slicer";
    exec = "crealityprint %F";
    icon = "CrealityPrint";
    terminal = false;
    type = "Application";
    categories = [ "Graphics" "Utility" ];
    mimeType = [
      "model/stl"
      "application/vnd.ms-3mfdocument"
      "application/prs.wavefront-obj"
      "application/x-amf"
    ];
  };

  # Icon shipped inside the AppImage (usr/share/icons/hicolor/192x192/apps/).
  xdg.dataFile."icons/hicolor/192x192/apps/CrealityPrint.png".source =
    "${appimageContents}/usr/share/icons/hicolor/192x192/apps/CrealityPrint.png";
}