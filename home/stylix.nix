{config, pkgs, inputs, ...}:

{
  stylix = {
    enable = true;
    autoEnable = true;

    targets = {
      fish.enable = true;
      kitty.enable = true;
      wofi.enable = true;
      waybar.enable = true;
      neovim.enable = true;
      nixcord.enable = true;
      blender.enable = true;
      dunst.enable = true;
      firefox.enable = true;
      bat.enable = true;
      yazi.enable = true;
      btop.enable = true;
    };
    
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyodark-terminal.yaml";

    cursor = {
      package = pkgs.simp1e-cursors;
      name = "Simple-Nord-Dark";
      size = 14;
    };

    fonts = {
      #serif     = config.stylix.fonts.monospace;
      #sansSerif = config.stylix.fonts.monospace;
      #emoji     = config.stylix.fonts.monospace;
      monospace = {package = pkgs.nerd-fonts.adwaita-mono;};
    };

    image = ./wallpaper/puffy-stars.jpg;

    polarity = "dark";
  };

  home.packages = with pkgs; [
    base16-schemes
    nerd-fonts.adwaita-mono
  ];
}

