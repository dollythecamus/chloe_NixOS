{config, system, inputs, ...}:

{
  services.openssh.enable = true;
  environment.systemPackages = [
    inputs.agenix.packages."${system}".default
  ];

  age.secrets.secret1.file = ./secrets/secret1.age;

  age.secrets.openclaw_gateway_token = {
    file = ./secrets/openclaw/gateway_token.age;
    owner = "chloe";  # Your username
    group = "users";
    mode = "0400";
  };
  
  age.secrets.discord_bot_token = {
    file = ./secrets/openclaw/discord_token.age;
    owner = "chloe";
    group = "users";
    mode = "0400";
  };

  environment.sessionVariables = {
    OPENCLAW_GATEWAY_TOKEN = builtins.readFile age.secrets.openclaw_gateway_token.path;
    OPENCLAW_DISCORD_BOT_TOKEN = builtins.readFile age.secrets.discord_bot_token.path;
  };
  
}