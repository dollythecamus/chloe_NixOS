{
  description = "Chloe's NixOS Configuration Flake";

  inputs = {
    
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # llm:

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    lmstudio = {
      url = "github:Daaboulex/lmstudio-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, stylix, ...} @ inputs: 
  let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
	      config.allowUnfree = true;
      };
  in
  {
    nixosConfigurations = {
      chloe-laptop = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs system pkgs-unstable; };
        modules = [

          ./host_chloe-laptop.nix
          ./modules/llm.nix
          ./modules/hermes.nix
          inputs.hermes-agent.nixosModules.default
          inputs.agenix.nixosModules.default
    
          home-manager.nixosModules.home-manager {
            home-manager.backupFileExtension = "__backup";
            home-manager.useGlobalPkgs = true;
            home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
            home-manager.users.chloe = ./home/chloe.nix;
            home-manager.sharedModules = [
              inputs.nixcord.homeModules.nixcord
              inputs.stylix.homeModules.stylix
              ];
          }
        ];
      };
    };
  };
}