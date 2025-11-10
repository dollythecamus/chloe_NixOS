{ config, pkgs, inputs, ...}:

{

  users.users.chloe= {
      isNormalUser = true;
      description = "Dr. Chloe Inventor";
      extraGroups = [ "networkmanager" "wheel" "dialout" "bluetooth" "input"];
       };
}
