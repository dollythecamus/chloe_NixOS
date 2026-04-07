{config, pkgs, pkgs-unstable, inputs, ...}:

{

  # let openclaw configure :p
  programs.openclaw = {
    package = pkgs-unstable.openclaw;
    # documents = ~/openclaw/documents;
    instances.default = {
      enable = true;
      stateDir = "~/.openclaw";
    };
  };

  /* # set in secrets.nix instead
  # Set environment variable for gateway token
  environment.sessionVariables = {
    OPENCLAW_GATEWAY_TOKEN = builtins.readFile age.secrets.openclaw_gateway_token.path;
    OPENCLAW_DISCORD_BOT_TOKEN = builtins.readFile age.secrets.discord_bot_token.path;
  };
  */
  
}
