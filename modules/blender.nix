{ config, pkgs, system, inputs, ...}:

{
    # install blender
    environment.systemPackages = with pkgs; [
      blender
    ];
    
    # for blender to use cuda support and render with GPU
    nixpkgs.overlays = [
    (final : prev: {
        blender = prev.blender.override {
            cudaSupport = true;
        };
        }
    )];
}