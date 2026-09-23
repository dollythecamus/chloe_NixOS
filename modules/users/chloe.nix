{ config, pkgs, inputs, ...}:

{

  users.users.chloe= {
      isNormalUser = true;
      description = "its chloe";
      # Gateway runs as chloe (services.hermes-agent.user = "chloe"). Its cron
      # scheduler launches jobs via `systemd-run --user`, which needs a systemd
      # user manager → linger must be on, or no gateway cron job runs.
      linger = true;
      extraGroups = [ 
        "docker" 
        "networkmanager" 
        "wheel" 
        "dialout" 
        "bluetooth" 
        "input"
        "pipewire"
        "hermes"
      ];
  };
}
