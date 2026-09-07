{config, system, inputs, ...}:

{
  services.openssh.enable = true;
  environment.systemPackages = [
    inputs.agenix.packages."${system}".default
  ];

  age.identityPaths = [ 
    "/home/chloe/.ssh/id_ed25519_agenix" 
    "/etc/ssh/ssh_host_ed25519_key"
    ];

  age.secrets.hermes-env.file = ./secrets/hermes-env.age;
}
