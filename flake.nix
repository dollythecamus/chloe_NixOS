{
  description = "Chloe's NixOS Configuration Flake";

  inputs = {
    
    unstable_nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";

    home-manager = {
    	url = "github:nix-community/home-manager?ref=release-25.05";
    	inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix?ref=release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {self, nixpkgs, home-manager, stylix, ...} @ inputs: 
  {
	homeConfigurations.chloe-inventor = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            stylix.homeModules.stylix
            ./home/space-home.nix
          ];
        };

	nixosConfigurations = {
	  chloe-laptop = nixpkgs.lib.nixosSystem {

		specialArgs = { inherit inputs; };

		modules = [
			./hosts/chloe-laptop/configuration.nix
			./hardware/nvidia.nix

			home-manager.nixosModules.home-manager {
				home-manager.backupFileExtension = "backup";
				home-manager.useGlobalPkgs = true;
				home-manager.useUserPackages = true;
				home-manager.users.chloe-inventor = ./home/space-home.nix;
				home-manager.users.chloe = ./home/space-chloe.nix;
			}
			./modules/desktop/space-home.nix
			stylix.nixosModules.stylix

			# services, programs and system packages
			./modules/system-packages.nix
			./modules/services.nix 
			./modules/programs.nix

			./modules/users/chloe-inventor.nix
			./modules/users/chloe.nix
		];
	};};
	};
}
