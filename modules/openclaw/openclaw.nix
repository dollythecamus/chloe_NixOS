{config, lib, pkgs, pkgs-unstable, inputs, ...}:

{
  # annoying to configure it with the home-manager options
  programs.openclaw = {
    enable = true;
    # from unstable channel, more recent than nixpkgs stable
    # but actually works, unlike from the nix-openclaw module 
    package = pkgs-unstable.openclaw;
  };

  # configure openclaw.json with the configured file
  # hope it works
  home.file.".openclaw/openclaw.json" = lib.mkForce {
    source = ./openclaw.json;
    force = true;
  };
}
