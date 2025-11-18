{ config, pkgs, unstablePkgs, inputs, ...}:

{

  users.users.chloe= {
      isNormalUser = true;
      description = "Dr. Chloe Inventor";
      extraGroups = [ "docker" "networkmanager" "wheel" "dialout" "bluetooth" "input"];

	# need some unstable package? do it here!
	packages = with unstablePkgs; [
		godot
		btop
	];
  };
}
