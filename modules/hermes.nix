{config, pkgs, inputs, ... }:

{
    # SearXNG — self-hosted search engine
      # used by hermesn
    imports = [ 
      #./searxng.nix 
    ];

    services.hermes-agent = {
    enable = true;
    container = {enable = true; hostUsers = ["chloe"];};

    extraDependencyGroups = ["messaging" "hindsight"];
    # messaging  = discord
    # hindsight  = memory provider

    configFile = ./config/hermes/config.yaml;

    # Path to the environment files containing API tokens/keys
    environmentFiles = [ 
        config.age.secrets.hermes-env.path
    ];
    
    # links the 'hermes' CLI tool to system packages
    addToSystemPackages = true;
  };
}
