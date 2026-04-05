{config, pkgs, pkgs-unstable, inputs, ...}:

{
  programs.openclaw = {
    package = pkgs-unstable.openclaw;
    # documents = ~/openclaw/documents;
    config = {
        
	gateway = {
	  mode = "local";
	  auth = {
	    token = "GATEWAY_TOKEN :)";
	  };
	};

	channels = {
	  discord = {
	      
	  };
	};
    };

    instances.default = {
      enable = true;
      plugins = [
        # { source = "github:acme/hello-world"; }
        ];
      };
    };
}
