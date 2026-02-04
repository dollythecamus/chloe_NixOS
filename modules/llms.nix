{config, pkgs, unstablePkgs, inputs, lib,...}:

{

  environment.sessionVariables = rec {
    OLLAMA_API_BASE=http://127.0.0.1:11434;
  };

  environment.systemPackages = [
    pkgs.aider-chat-full
  ];

  services.ollama = {
    enable = true;
    package = unstablePkgs.ollama-vulkan;

  };
}
