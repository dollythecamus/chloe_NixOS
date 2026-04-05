{
  description = "Chloe's NixOS Configuration Flake";

  inputs = {
    
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
    	url = "github:nix-community/home-manager/release-26.11";
    	inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:FlameFlag/nixcord";
    };

    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-clawdbot = {
      url = "github:clawdbot/nix-clawdbot";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, stylix, ...} @ inputs: 
  let
      system = "x86_64-linux";
      unstablePkgs = import nixpkgs-unstable {
        inherit system; 
      };
  in

  {
    nixosConfigurations = {
      chloe-laptop = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs unstablePkgs; };
        modules = [

          ./host_chloe-laptop.nix
	  stylix.nixosModules.stylix
	
	  home-manager.nixosModules.home-manager.home-manager {
	    backupFileExtension = "backup";
	    useGlobalPkgs = true;
	    useUserPackages = true;
	    extraSpecialArgs = { inherit inputs; };
	    users.chloe = ./home/space-chloe.nix;
	    sharedModules = [
	      inputs.nixcord.homeModules.nixcord
	      ];
	    }
	  ];
        };

	# chloe's configuration that adds the openclaw module
	# this openclaw thing is. so scary.

      chloe-openclaw = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs unstablePkgs; };
	modules = [
	  ./host_chloe-laptop.nix
	  
	  ./modules/llms.nix
	  stylix.nixosModules.stylix

	  home-manager.nixosModules.home-manager.home-manager {
	    backupFileExtension = "backup";
	    useGlobalPkgs = true;
	    useUserPackages = true;
	    extraSpecialArgs = { inherit inputs; };
	    users.chloe = ./home/space-chloe.nix;
	    sharedModules = [
	      inputs.nixcord.homeModules.nixcord
	      nix-clawdbot.homeManagermodules.clawdbot
	      ./modules/clawdbot.nix
	      ];
	    }

	  ];
	};
    };
  
  };
}
