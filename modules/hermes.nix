{config, pkgs, inputs, ... }:

{
    # SearXNG — self-hosted meta search engine for web tool
    imports = [ ./searxng.nix ];

    services.hermes-agent = {
    enable = true;
    container = {enable = true; hostUsers = ["chloe"];};

    extraDependencyGroups = ["messaging" "hindsight"];
    # messaging  = discord
    # hindsight  = memory provider

    configFile = ./config/hermes/config.yaml;

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
