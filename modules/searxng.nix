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
  };
}
