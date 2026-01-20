{config, pkgs, unstablePkgs, inputs, lib,...}:

{
  environment.systemPackages = [
    pkgs.aider-chat-full
  ];

  services.ollama = {
    enable = true;
    package = unstablePkgs.ollama-vulkan;
  };
}
