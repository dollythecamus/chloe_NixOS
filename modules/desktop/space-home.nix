{config, pkgs, lib, inputs, ...}:

{
  # login manager
  services.displayManager.ly = {
    enable = true;
    # can configure more :3
  };

  # themed everything, easy
  inputs.stylix = {
    enable = true;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/black-metal-mayhem.yaml";

    cursor.package = pkgs.simp1e-cursors;
    cursor.name = Simp1e-Nord-Dark;

    # image = ;
  };

  # Enable Hyprland
  programs.hyprland.enable = true;

  # Enable Electron apps for wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,br";
    variant = "";
  };

}
