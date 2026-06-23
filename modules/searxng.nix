{config, pkgs, ...}:

{
  services.searx = {
    enable = true;
    settings = {
      search = {
        formats = [ "html" "json" ];
      };

      # Server configuration
      server = {
        port = 8888;
        bind_address = "127.0.0.1";
        limiter = true;
        public_instance = false;
      };
    };
    environmentFile = config.age.secrets.searxng_env.path;
  };
}
