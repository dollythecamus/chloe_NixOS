{config, pkgs, inputs, ... }:

{
    services.hermes-agent = {
    enable = true;
    /*
    # container for hermes environment
    container = {
      enable = true;
      hostUsers = [ "chloe" ];
    };
    */

    settings.model.default = "openrouter/owl-alpha";

    extraDependencyGroups = ["messaging"];
    # Path to the environment files containing API tokens/keys
    environmentFiles = [ 
        config.age.secrets.openrouter_token.path
        config.age.secrets.discord_bot_token.path
    ];
    
    # links the 'hermes' CLI tool to system packages
    addToSystemPackages = true;
  };
}
