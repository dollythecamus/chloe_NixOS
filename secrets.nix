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

  age.secrets.discord_bot_token.file = ./secrets/discord_token.age;
  age.secrets.hermes_env.file = ./secrets/hermes_env.age;
  age.secrets.searxng_env.file = ./secrets/searxng_env.age;
}
