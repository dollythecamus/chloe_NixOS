{
  description = "Chloe's NixOS Configuration Flake";

  inputs = {
    
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";

    nixcord = {
      url = "github:kaylorben/nixcord";
    };

    home-manager = {
    	url = "github:nix-community/home-manager?ref=release-25.11";
    	inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix?ref=release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # bongocat.url = "github:furudbat/wayland-vpets";
  
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
            ./home/space-home.nix
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
				home-manager.users.chloe-inventor = ./home/space-home.nix;
				home-manager.users.chloe = ./home/space-chloe.nix;

				home-manager.sharedModules = [
				        #stylix.homeModules.stylix
             				inputs.nixcord.homeModules.nixcord
           			];
			}		
			
			/*
			# not working :(

			inputs.bongocat.nixosModules.default {
          			programs.wayland-bongocat = {
            			enable = true;
            			autoStart = true;
					inputDevices = [
						"/dev/input/event4"
					];
          			};
        		}

			*/
			
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
