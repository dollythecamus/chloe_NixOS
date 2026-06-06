{config, pkgs, pkgs-unstable, inputs, ...}:

{
  # annoying to configure it with the home-manager options
  programs.openclaw = {
    enable = true;
    package = pkgs-unstable.openclaw;
  };

  # configure with openclaw.json
  # hope it works
  home.file.".openclaw/openclaw.json" = {
    source = ./openclaw.json;
  };
}
