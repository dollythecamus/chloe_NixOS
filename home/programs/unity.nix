{config, pkgs, ...}:

{
  # unity for gamedev
  # used to be installed with flatpak but it is giving me problems

  # https://huantian.dev/blog/unity3d-rider-nixos/
  # some help

  # ncurses6 (libtinfo.so.6) must be in the Hub's FHS sandbox: the bundled
  # Editor/Data/Tools/UnityShaderCompiler links against it, and without it
  # every project dies at startup with
  #   "Shader compiler initialization error: Failed to get ipc connection
  #    from UnityShaderCompiler ... 0x80000008 (Timed out)"
  # Upstream unityhub's buildFHSEnv doesn't ship libtinfo, so inject it via
  # the package's extraLibs hook. See ~/.local/share/Trash/files/lvl_probuilder/Logs/Editor.log
  # (2026-09-08) for the original crash trace.
  home.packages = with pkgs; [
    (unityhub.override {
      extraLibs = p: [ p.ncurses6 ];
    })
  ];
}
