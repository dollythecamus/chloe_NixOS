{ config, pkgs, inputs, ...}:

{

  users.users.chloe= {
      isNormalUser = true;
      description = "chloeee";
      extraGroups = [ "docker" "networkmanager" "wheel" "dialout" "bluetooth" "input"];

	# need some unstable package? do it here!
	packages = with inputs.nixpkgs-unstable.legacyPackages.x86_64-linux; [
	  godot
	  btop
	];
  };
}
