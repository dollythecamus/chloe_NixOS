{config, inputs, ...}:

{
  # ly login manager
  services.displayManager.ly = {
    enable = true;
    
    settings = {
      clock = "%c";
      bigclock = true;
      animate = true;
      animation = "matrix";
    };
    # can configure more :3
    # ly is pretty >~<
  };
}
