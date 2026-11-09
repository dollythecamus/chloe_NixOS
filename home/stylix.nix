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
      base00 = "f6edec"; base01 = "fff8f7"; base02 = "ead1d8";
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

  # 2026-11-02: `home-manager-chloe` failed to start on switch ("Existing file
  # '/home/chloe/Mind/.obsidian/appearance.json.__backup' would be clobbered by
  # backing up '/home/chloe/Mind/.obsidian/appearance.json'") and the profile
  # stayed on the previous generation. Cause: the stylix obsidian target above
  # writes appearance.json into the vault, but Obsidian rewrites that file
  # itself -- a save replaces HM's symlink with a regular file -- so the next
  # switch tried to back it up again and the September backup was already
  # there, which checkLinkTargets treats as a hard error. Obsidian owns the
  # runtime writes, HM owns the declaration, so let HM win: force skips the
  # collision check and replaces the file with the styled version (the file in
  # the way still lands in appearance.json.__backup).
  home.file."Mind/.obsidian/appearance.json".force = true;

  home.packages = with pkgs; [
    base16-schemes
    vanilla-dmz
    nerd-fonts.adwaita-mono
    adwaita-icon-theme
  ];
}

