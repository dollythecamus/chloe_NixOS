{config, pkgs, ...}:

{
  # search engine used by hermes 
  # not used currently! 
  services.searx = {
    enable = true;
    settings = {
      search = {
        formats = [ "html" "json" ];
      };

      # Server configuration
      server = {
        port = 8888;
        bind_address = "0.0.0.0";
        secret_key = config.age.secrets.searxng_env.path;
        limiter = true;
        public_instance = false;
      };
    };
  };
}
