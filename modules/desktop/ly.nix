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
      # Mission-control light palette: warm off-white, plum text, pink accents.
      # Ly expects true-color INI values in 0xSSRRGGBB notation.
      fg = "0x00481D32";
      bg = "0x00F6EDEC";
      border_fg = "0x00AE3158";
      error_fg = "0x01B3234E";
      cmatrix_fg = "0x00AE3158";
      cmatrix_head_col = "0x01F6EDEC";
    };
    # can configure more :3
    # ly is pretty >~<
  };
}
