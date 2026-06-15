{config, pkgs, inputs, ... }:

{
    services.hermes-agent = {
    enable = true;
    
    # container for hermes environment
    container = {
      enable = true;
      hostUsers = [ "chloe" ];
    };
    extraDependencyGroups = ["messaging" "hindsight" "exa" ];
    # messaging = discord
    # hindsight = memory provider
    # exa       = web search
    
    settings = {
      model = {
        default = "openrouter/nex-agi/nex-n2-pro:free";
        provider = "openrouter";
      };
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
      tools = {

      };
    };

    # Path to the environment files containing API tokens/keys
    environmentFiles = [ 
        config.age.secrets.openrouter_token.path
        config.age.secrets.discord_bot_token.path
    ];
    
    # links the 'hermes' CLI tool to system packages
    addToSystemPackages = true;
  };
}
