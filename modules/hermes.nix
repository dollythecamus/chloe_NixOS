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
        default = "local";
      };
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
      web = {
        backend = "searxng";
        search_backend = "searxng";
      };

      custom_provider = {
        name = "local";
        base_url = "https://127.0.0.1:11434/"; # ollama API base URL
        model = "jetelain/Qwen3.6-35B-A3B:latest";
      };
    };

    environment = {
      SEARXNG_URL = "http://127.0.0.1:8080";
      OLLAMA_API_BASE_URL="http://127.0.0.1:11434/";
      OLLAMA_API_BASE="http://127.0.0.1:11434/";
    };

    # Path to the environment files containing API tokens/keys
    environmentFiles = [ 
        config.age.secrets.hermes_env.path
    ];
    
    # links the 'hermes' CLI tool to system packages
    addToSystemPackages = true;
  };
}
