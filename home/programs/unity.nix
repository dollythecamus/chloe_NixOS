{config, pkgs, ...}:

# unity for gamedev (was flatpak, gave problems)
# https://huantian.dev/blog/unity3d-rider-nixos/

{
  # Two sandbox fixes are needed for the Unity *editor* to launch projects:
  #
  # 1. extraLibs: the bundled Data/Tools/UnityShaderCompiler links against
  #    ncurses libtinfo.so.6, which nixpkgs' unityhub FHS sandbox lacks
  #    (Ubuntu ships it system-wide). Without it: "Failed to get ipc
  #    connection from UnityShaderCompiler ... 0x80000008 (Timed out)".
  #
  # 2. LD_LIBRARY_PATH: even after 1, the ld.so cache regenerated inside
  #    the sandbox at startup does not contain the ncurses entries, so the
  #    loader can't find the lib by name. Forcing /usr/lib64:/usr/lib onto
  #    LD_LIBRARY_PATH in the launcher wrapper (env passes through bwrap)
  #    makes every sandboxed process — editor, shader compiler, import
  #    workers — resolve sandbox libs. Verified 2026-09-09: with the var
  #    set, UnityShaderCompiler runs; without it, same load error.
  home.packages = with pkgs; [
    ((unityhub.override { extraLibs = p: [ p.ncurses6 ]; }
    ).overrideAttrs (final: prev: {
      installPhase = prev.installPhase + ''
        sed -i '1a export LD_LIBRARY_PATH="/usr/lib64:/usr/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"' \
          $out/opt/unityhub/unityhub
      '';
    }))
  ];
}
