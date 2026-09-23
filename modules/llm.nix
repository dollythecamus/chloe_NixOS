{config, inputs, pkgs, pkgs-unstable,...}:

{
  environment.systemPackages = [
    # opencode, for vibe coding
    pkgs-unstable.opencode
    # lm studio for running local llms
    inputs.lmstudio.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

}
