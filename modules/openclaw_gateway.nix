{config, pkgs-unstable, inputs, ...}:

{
  # Systemd user service for openclaw gateway
  systemd.user.services.openclaw-gateway = {
    enable = true;
    description = "OpenClaw Gateway Service";
    documentation = [ "https://github.com/openclaw/openclaw" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs-unstable.openclaw}/bin/openclaw gateway";
      Restart = "on-failure";
      RestartSec = 5;
    };
    
    wantedBy = [ "default.target" ];
  };

}