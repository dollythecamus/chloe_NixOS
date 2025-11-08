{
  description = "Chloe's NixOS Configuration Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgsStable.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgsStable";
  };

  outputs = {self, ...} @ inputs: 
  let
  	pkgs = inputs.nixpkgsStable.pkgs.x86_64-linux;
  	upkgs = inputs.nixpkgs.pkgs.x86_64-linux; 
  in
  {
	chloe = pkgs.lib.nixosSystem {
		specialArgs = { inherit inputs; };

		modules = [
			./chloe-nixos.nix
			/etc/nixos/hardware-configuration.nix
		];
	};
  };
}
