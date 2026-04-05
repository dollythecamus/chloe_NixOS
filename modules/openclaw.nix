{config, pkgs, pkgs-unstable, inputs, ...}:

{
  programs.openclaw = {
    package = pkgs-unstable.openclaw;
    # documents = ~/openclaw/documents;
    
    config = {
      gateway = {
        mode = "local";
        # Gateway auth token - use environment variable at runtime
        # Set OPENCLAW_GATEWAY_TOKEN environment variable on your system
        auth = {
          token = builtins.getEnv "OPENCLAW_GATEWAY_TOKEN";
        };
        # WebSocket port (default: 18789)
        # If you need remote access, change mode to "remote" and adjust port
        port = 18789;
      };

      channels = {
        # Discord channel configuration
        # Uncomment and configure when ready
        # discord = {
        #   token = builtins.getEnv "DISCORD_BOT_TOKEN";
        #   allowFrom = [ "YOUR_DISCORD_USER_ID" ];
        #   dmPolicy = "pairing";  # Require pairing code for unknown senders
        # };
        
        # Telegram channel configuration
        # Uncomment and configure when ready
        # telegram = {
        #   botToken = builtins.getEnv "TELEGRAM_BOT_TOKEN";
        #   allowFrom = [ 123456789 ];  # Your Telegram user ID
        # };
      };
    };

    instances.default = {
      enable = true;
      # Explicitly set stateDir and workspaceDir
      stateDir = "~/.openclaw";
      workspaceDir = "~/.openclaw/workspace";
      
      plugins = [
        # Example plugin configuration
        # { source = "github:openclaw/nix-steipete-tools?dir=tools/peekaboo"; }
      ];
    };
  };

  # Set environment variable for gateway token
  # IMPORTANT: Change this to a real token or use agenix for secrets management
  /*
  environment.sessionVariables = {
    OPENCLAW_GATEWAY_TOKEN = "your-secure-gateway-token-here";
  };
  */
}
