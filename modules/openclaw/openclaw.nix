{config, lib, pkgs-unstable, inputs, ...}:

{
  # annoying to configure it with the home-manager options
  programs.openclaw = {
    enable = true;
    # from the nix-openclaw flake
    package = inputs.nix-openclaw.packages.${config.system}.openclaw;
  };

  # configure openclaw.json with the configured file
  # hope it works
  home.file.".openclaw/openclaw.json" = lib.mkForce {
    source = ./openclaw.json;
    force = true;
  };
}
