{config, inputs, pkgs-unstable,...}:

{
  environment.systemPackages = [
    # opencode, for vibe coding
    pkgs-unstable.opencode
    inputs.lmstudio.packages.${pkgs.system}.default
  ];

}
