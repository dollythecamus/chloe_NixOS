{config, pkgs, ...}:

{
  services.searx = {
    enable = true;
    settings = {
      server.port = 8080;
      search = {
        formats = [ "html" "json" ];
      };
    };
    secret_key = config.age.secrets.searxng_env.path;
  };
}
