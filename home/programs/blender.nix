{ config, pkgs, inputs, ...}:

let
  # CUDA Blender comes from its own nixpkgs pin (flake input `nixpkgs-blender`),
  # not the main `nixpkgs`. Reason: the cudaSupport=true variant has no
  # cache.nixos.org binary, so it is compiled locally (~hours) -- pinning it
  # separately keeps `nix flake update nixpkgs` from forcing that rebuild on
  # every security bump. allowUnfree is set here because a separately imported
  # nixpkgs does not inherit the flake's allowUnfree. System comes from
  # pkgs.stdenv: `system` is NOT an argument home-manager modules receive
  # (declaring it evaluates fine only until it is actually referenced).
  blenderPkgs = import inputs.nixpkgs-blender {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  blenderCuda = blenderPkgs.blender.override {
    cudaSupport = true;
  };
in
{
    # install blender (cuda build, GPU rendering)
    home.packages = [
      blenderCuda
    ];

    # Kept as an overlay rather than a bare package entry so stylix's blender
    # target resolves this same build: it writes its theme preset into
    # ~/.config/blender/<pkgs.blender.version>/, and a version mismatch between
    # the package and the target would silently theme a directory that does not
    # exist. Note this overlay lives in home-manager's pkgs (useGlobalPkgs is
    # false); system pkgs are untouched.
    nixpkgs.overlays = [
      (final: prev: {
        blender = blenderCuda;
      })
    ];
}
