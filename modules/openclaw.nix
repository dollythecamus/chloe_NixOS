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

  /*
  # Set environment variable for gateway token
  home.sessionVariables = {
    OPENCLAW_GATEWAY_TOKEN = config.age.secrets.openclaw_gateway_token.path;
    OPENCLAW_DISCORD_BOT_TOKEN = config.age.secrets.discord_bot_token.path;
  };
  */
}
