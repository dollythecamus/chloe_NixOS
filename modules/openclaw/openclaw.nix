{config, lib, pkgs-unstable, inputs, ...}:

{
  # annoying to configure it with the home-manager options
  programs.openclaw = {
    enable = true;
    package = pkgs-unstable.openclaw;
  };

  # configure openclaw.json with the configured file
  # hope it works
  home.file.".openclaw/openclaw.json" = lib.mkForce {
    source = ./openclaw.json;
    force = true;
  };
}
