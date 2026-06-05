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

  age.secrets.openclaw_gateway_token.file = ./secrets/openclaw/gateway_token.age;
  age.secrets.discord_bot_token.file = ./secrets/openclaw/discord_token.age;

  # shell at startup to define the gateway token by getting the secret
  environment.shellInit = ''
    if [ -f ${config.age.secrets.openclaw_gateway_token.path} ]; then
      export OPENCLAW_GATEWAY_TOKEN=$(cat ${config.age.secrets.openclaw_gateway_token.path})
      export OPENCLAW_DISCORDBOT_TOKEN=$(cat ${config.age.secrets.discord_bot_token.path})
      
    fi
  '';

  environment.sessionVariables = {
  };
  
}
