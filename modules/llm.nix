{config, pkgs-unstable,...}:

{
  environment.systemPackages = [
    pkgs-unstable.opencode
  ];

  environment.sessionVariables = {
    OLLAMA_API_BASE_URL="http://127.0.0.1:11434";
    OLLAMA_API_BASE="http://127.0.0.1:11434";
    OLLAMA_API_KEY = "ollama-local";
  };

  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-cuda;
    
    host = "127.0.0.1";
    port = 11434;
  };

}
