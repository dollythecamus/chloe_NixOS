{config, pkgs, pkgs-unstable, inputs, ...}:

{
  programs.openclaw = {
    enable = true;
    package = pkgs-unstable.openclaw;
    # documents = ~/openclaw/documents;
    config = {
      gateway.mode = "local";
    };
      #instances.default = {
      #  enable = true;
      #  stateDir = "~/.openclaw";
      #};
  };
}
