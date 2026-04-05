{config, system, inputs, ...}:

{
  services.openssh.enable = true;
  age.secrets.secret1.file = ./secrets/secret1.age;

  environment.systemPackages = [
    inputs.agenix.packages."${system}".default
  ];
}