{
  description = "Chloe's NixOS Configuration Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {self, nixpkgs, ...} @ inputs: 
  {
	nixosConfigurations.chloe = nixpkgs.lib.nixosSystem {
		specialArgs = { inherit inputs; };

		modules = [
			./chloe-nixos.nix
			/etc/nixos/hardware-configuration.nix
		];
	};
  };
}
