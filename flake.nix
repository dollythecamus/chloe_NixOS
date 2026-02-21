{
  description = "Chloe's NixOS Configuration Flake";

  inputs = {
    
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nixcord = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:FlameFlag/nixcord";
    };

    home-manager = {
    	url = "github:nix-community/home-manager/release-25.11";
    	inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = {self, nixpkgs, nixpkgs-unstable, home-manager, stylix, ...} @ inputs: 
  let
      system = "x86_64-linux";
      unstablePkgs = import nixpkgs-unstable {
        inherit system; 
      };
  in

  {
  	# no idea if this works actually
	homeConfigurations.chloe-inventor = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            stylix.homeModules.stylix
            ./home/space-chloe.nix
          ];
        };

	nixosConfigurations = {
	  chloe-laptop = nixpkgs.lib.nixosSystem {

		specialArgs = { inherit inputs unstablePkgs; };

		modules = [
			./hosts/chloe-laptop/configuration.nix
			./hardware/nvidia.nix

			home-manager.nixosModules.home-manager {

				home-manager.backupFileExtension = "backup";
				home-manager.useGlobalPkgs = true;
				home-manager.useUserPackages = true;
				#home-manager.users.chloe-inventor = ./home/space-home.nix;
				home-manager.users.chloe = ./home/space-chloe.nix;

				home-manager.sharedModules = [ # what does this do? who knows ? :)
				        #stylix.homeModules.stylix
             			inputs.nixcord.homeModules.nixcord
           			];
			}		
			
			# style thing
			./modules/desktop/space-home.nix
			stylix.nixosModules.stylix

			# services, programs and system packages
			./modules/system-packages.nix
			./modules/services.nix 
			./modules/programs.nix
			./modules/syncthing.nix
			./modules/llms.nix

			./modules/users/chloe-inventor.nix
			./modules/users/chloe.nix
		];
	};};
	};
}
