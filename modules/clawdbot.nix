{config, pkgs, inputs, ...}:

{
  programs.clawdbot = {
  
  # documents = ~/openclaw/documents;
  
  instances.default = {
    enable = true;
    providers.telegram = {
        enable = false;
          # nope!
	  /*
	  botTokenFile = "<tokenPath>";
	  allowFrom = [ <allowFrom> ];
	  groups = {
	      "*" = { requireMention = true; };
	    };
	  */
	  };
	# nope!
	/*
	providers.anthropic = {
	    apiKeyFile = "<anthropicKeyPath>";
	  };
	*/
	
	providers.ollama = {  
	  };
	
	plugins = [
	    # { source = "github:acme/hello-world"; }
	  ];
	};
    };
}

