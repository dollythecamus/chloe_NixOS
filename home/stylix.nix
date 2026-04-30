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

      obsidian = {
        enable = true;
        vaultNames = ["Mind"];
      };
    };
    
    cursor = {
      name = "DMZ-Black";
      size = 24;
      package = pkgs.vanilla-dmz;
    };

    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

    fonts = {
      # all monospace
      serif     = {package = pkgs.nerd-fonts.adwaita-mono; name = "AdwaitaMono Nerd Font"; };
      sansSerif = {package = pkgs.nerd-fonts.adwaita-mono; name = "AdwaitaMono Nerd Font"; };
      # emoji     = config.stylix.fonts.monospace;
      monospace = {package = pkgs.nerd-fonts.adwaita-mono; name = "AdwaitaMono Nerd Font"; };
    };

    image = ./wallpaper/puffy-stars.jpg;

    polarity = "dark";
  };

  home.packages = with pkgs; [
    base16-schemes
    vanilla-dmz
    nerd-fonts.adwaita-mono
  ];
}

