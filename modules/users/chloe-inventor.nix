{ config, pkgs, inputs, ...}:

{

  users.users.chloe-inventor= {
      isNormalUser = true;
      description = "Dr. Chloe Inventor";
      extraGroups = [ "networkmanager" "wheel" "dialout" "bluetooth" "input"];
       };
}
