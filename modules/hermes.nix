{config, pkgs, inputs, ... }:

{
    services.hermes-agent = {
    enable = true;
    # container enables more configuration in the hermes environment
    container.enable = true;
    container.hostUsers = [ "chloe" ];
    
    settings.model.default = "openrouter/moonshotai/kimi-k2.6:free"; 
    
    # Path to the environment files containing API tokens/keys
    environmentFiles = [ 
        config.age.secrets.openrouter_token.path
        config.age.secrets.discord_bot_token.path
    ];
    
    # links the 'hermes' CLI tool to system packages
    addToSystemPackages = true;
  };
}
