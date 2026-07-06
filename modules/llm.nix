{config, pkgs-unstable,...}:

{
  environment.systemPackages = [
    pkgs-unstable.opencode
  ];

  environment.sessionVariables = {
    OLLAMA_API_BASE_URL="http://0.0.0.0:11434/v1";
    OLLAMA_API_BASE="http://0.0.0.0:11434/v1";
    OLLAMA_API_KEY = "ollama-local";
  };

  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-cuda;
    
    host = "0.0.0.0";
    port = 11434;
  };

}
