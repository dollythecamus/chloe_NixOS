{
  description = "Chloe's NixOS Configuration Flake";

  inputs = {
    
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";

    nixcord = {
      url = "github:kaylorben/nixcord";
    };

    home-manager = {
    	url = "github:nix-community/home-manager?ref=release-25.05";
    	inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix?ref=release-25.05";
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

			{ # weird but alright
           		 # Here you mix a package from unstable
            		 environment.systemPackages = [
          		    unstablePkgs.godot
        		    ];
        		}

			home-manager.nixosModules.home-manager {
				home-manager.backupFileExtension = "backup";
				home-manager.useGlobalPkgs = true;
				home-manager.useUserPackages = true;
				home-manager.users.chloe-inventor = ./home/space-home.nix;
				home-manager.users.chloe = ./home/space-chloe.nix;

				home-manager.sharedModules = [
				        #stylix.homeModules.stylix
             				inputs.nixcord.homeModules.nixcord
           			];
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
