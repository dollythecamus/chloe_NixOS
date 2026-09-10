{
  config,
  lib,
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
  # approach nixpkgs takes for cura-appimage.
  pname = "crealityprint";
  version = "7.2.1.5476";

  src = pkgs.fetchurl {
    url = "https://github.com/CrealityOfficial/CrealityPrint/releases/download/v7.2.1/CrealityPrint-V${version}-x86_64-Release.AppImage";
    hash = "sha256-so9mwl0MZlLtauSdB2Z4D0aluDm5POGWjmOYI+H24vM=";
  };

  # The AppImage's bin/CrealityPrint is a monolithic static-Qt build that still
  # NEEDs the system GTK/GL/WebKit stack. Its AppRun RE-EXPORTS LD_LIBRARY_PATH
  # to only the AppImage's own bin/ + usr/lib, which hides the FHS env's
  # /usr/lib64 from the loader (first failure: libbz2/libstdc++ not found).
  # Patch AppRun to append the env library dirs after the bundled ones.
  appimageContents = pkgs.appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      sed -i 's|export LD_LIBRARY_PATH=.*|export LD_LIBRARY_PATH="$DIR/bin:$DIR/usr/lib:/usr/lib64:/usr/lib"|' $out/AppRun
    '';
  };

  # wrapAppImage (not wrapType2) so the patched extract is used as-is instead
  # of being re-extracted from the pristine AppImage.
  crealityprint = pkgs.appimageTools.wrapAppImage {
    inherit pname version;
    src = appimageContents;
    # Additional system libs beyond appimageTools' default rootfs, matched to
    # `patchelf --print-needed bin/CrealityPrint` (webkit/gtk stack of the
    # Creality Cloud views; the rest already come from the default multiPkgs).
    extraPkgs = p: with p; [
      webkitgtk_4_1 # libwebkit2gtk-4.1 + libjavascriptcoregtk-4.1
      libsoup_3 # libsoup-3.0 (webkit dep)
      libdeflate # libdeflate.so.0
      zstd # libzstd.so.1
      gcc-unwrapped.lib # libstdc++.so.6 + libatomic.so.1
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