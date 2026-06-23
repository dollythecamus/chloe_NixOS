{config, pkgs, inputs, ... }:

{
    # SearXNG — self-hosted meta search engine for web tool
    imports = [ ./searxng.nix ];

    services.hermes-agent = {
    enable = true;

    # container for hermes environment
    container = {
      enable = true;
      hostUsers = [ "chloe" ];
    };
    extraDependencyGroups = ["messaging" "hindsight"];
    # messaging  = discord
    # hindsight  = memory provider

    settings = {
      model = {
        default = "openrouter/nex-agi/nex-n2-pro:free";
        provider = "openrouter";
      };
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
      web = {
        backend = "searxng";
        search_backend = "searxng";
      };
      tools = {

      };
    };

    environment = {
      SEARXNG_URL = "http://127.0.0.1:8080";
    };

    # Path to the environment files containing API tokens/keys
    environmentFiles = [ 
        config.age.secrets.hermes_env.path
    ];
    
    # links the 'hermes' CLI tool to system packages
    addToSystemPackages = true;
  };
}
