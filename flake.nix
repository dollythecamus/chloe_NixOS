{
  description = "Chloe's NixOS Configuration Flake";

  inputs = {
    
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
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

    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, stylix, ...} @ inputs: 
  let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
	      config.allowUnfree = true;
        config.permittedInsecurePackages = [
          "openclaw-2026.4.2"
        ];
      };
  in
  {
    nixosConfigurations = {
      chloe-laptop = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs system pkgs-unstable; };
        modules = [

          ./host_chloe-laptop.nix
          inputs.agenix.nixosModules.default
    
	  #stylix.nixosModules.stylix
	
	  home-manager.nixosModules.home-manager {
	    home-manager.backupFileExtension = "backup";
	    home-manager.useGlobalPkgs = false;
	    home-manager.useUserPackages = true;
	    home-manager.extraSpecialArgs = { inherit inputs; };
	    home-manager.users.chloe = ./home/chloe.nix;
	    home-manager.sharedModules = [
	      inputs.nixcord.homeModules.nixcord
	      inputs.stylix.homeModules.stylix
	      ];
	    }
	  ];
        };

      # regular configuration, added LLMs modules and openclaw
      chloe-llm = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs system pkgs-unstable; };
	modules = [

	  ./host_chloe-laptop.nix
	  ./modules/llm.nix
    inputs.agenix.nixosModules.default

	  # stylix.nixosModules.stylix

	  home-manager.nixosModules.home-manager {
	    home-manager.backupFileExtension = "__backup";
	    home-manager.useGlobalPkgs = false;
	    home-manager.useUserPackages = true;
	    home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
	    home-manager.users.chloe = ./home/chloe.nix;
	    home-manager.sharedModules = [
	      inputs.nixcord.homeModules.nixcord
	      inputs.stylix.homeModules.stylix
	      inputs.nix-openclaw.homeManagerModules.openclaw
              ./modules/openclaw.nix
              ./home/aider.nix
	      ];
	    }

	  ];
	};
    };
  
  };
}
