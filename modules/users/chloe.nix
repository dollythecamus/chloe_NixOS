{ config, pkgs, inputs, ...}:

{

  users.users.chloe= {
      isNormalUser = true;
      description = "its chloe";
      extraGroups = [ 
        "docker" 
        "networkmanager" 
	"wheel" 
	"dialout" 
	"bluetooth" 
	"input"
	"pipewire"
  "hermes"
      ];
  };
}
