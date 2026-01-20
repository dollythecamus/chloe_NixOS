{config, pkgs, inputs, ...}:

{
  environment.systemPackages = [
    pkgs.aider-chat-full
    pkgs.ollama
  ];

  services.ollama = {
    enable = true;

    acceleration = "cuda";
  };

}
