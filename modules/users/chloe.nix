{ config, pkgs, inputs, ...}:

{

  users.users.chloe= {
      isNormalUser = true;
      description = "chloeee";
      extraGroups = [ 
        "docker" 
        "networkmanager" 
	"wheel" 
	"dialout" 
	"bluetooth" 
	"input"
	"pipewire"
      ];
  };
}
