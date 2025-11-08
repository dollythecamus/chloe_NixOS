{
  description = "Chloe's NixOS Configuration Flake";

  inputs = {
    unstable_nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {self, nixpkgs, ...} @ inputs: 
  {
	nixosConfigurations.chloe-laptop = nixpkgs.lib.nixosSystem {
		specialArgs = { inherit inputs; };

		modules = [
			./hosts/chloe-laptop/configuration.nix
			./modules/hardware/nvidia.nix

			# desktop modules 
			./modules/desktop/space-home.nix # abstract

			# services, programs and system packages
			./modules/system-packages.nix
			./modules/services.nix # abstract
			./modules/programs.nix # abstract
		
			./modules/users/chloe-inventor.nix
			./modules/users/chloe-games.nix # abstract
		];
	};
  };
}
