{config, pkgs, inputs, desktop, ...}:

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

    base16Scheme = if desktop == "sway-prototype" then {
      base00 = "f6eceb"; base01 = "fff8f7"; base02 = "ead1d8";
      base03 = "957380"; base04 = "715263"; base05 = "481d32";
      base06 = "38202c"; base07 = "250c23"; base08 = "b3234e";
      base09 = "ae3158"; base0A = "9e5853"; base0B = "7d4358";
      base0C = "715c76"; base0D = "8e3d6f"; base0E = "ae3158";
      base0F = "674c5a";
    } else "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";

    fonts = {
      # all monospace
      serif     = {package = pkgs.nerd-fonts.adwaita-mono; name = "AdwaitaMono Nerd Font"; };
      sansSerif = {package = pkgs.nerd-fonts.adwaita-mono; name = "AdwaitaMono Nerd Font"; };
      # emoji     = config.stylix.fonts.monospace;
      monospace = {package = pkgs.nerd-fonts.adwaita-mono; name = "AdwaitaMono Nerd Font"; };
    };

    # image = ./wallpaper/puffy-stars.jpg;

    polarity = if desktop == "sway-prototype" then "light" else "dark";
  };

  home.packages = with pkgs; [
    base16-schemes
    vanilla-dmz
    nerd-fonts.adwaita-mono
    adwaita-icon-theme
  ];
}

