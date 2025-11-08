{
  description = "A very basic flake";

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
	nixosConfiguration.nixos = nixpkgs.lib.nixosSystem {
		specialArgs = { inherit inputs; };

		modules = [
			./configuration.nix
			./hardware-configuration.nix

		];
	};
  };
}
