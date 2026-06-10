{config, system, inputs, ...}:

{
  services.openssh.enable = true;
  environment.systemPackages = [
    inputs.agenix.packages."${system}".default
  ];

  age.identityPaths = [ 
    "/home/chloe/.ssh/id_ed25519" 
    "/etc/ssh/ssh_host_ed25519_key"
    ];

  #age.secrets.auth_secret1.file = ./secrets/auth_secret1.age;

  age.secrets.discord_bot_token.file = ./secrets/discord_token.age;
  age.secrets.openrouter_token.file = ./secrets/openrouter_token.age;

  environment.sessionVariables = {
    DISCORD_BOT_TOKEN="${config.age.secrets.discord_bot_token.path}";
    OPENROUTER_API_KEY="${config.age.secrets.openrouter_token.path}";
  };
  
}
