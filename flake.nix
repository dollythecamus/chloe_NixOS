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

      # One host, two desktop stacks. `desktop` is a module argument (passed
      # through specialArgs), so host_chloe-laptop.nix picks the login manager
      # and the desktop layer from it:
      #   niri   -- the live configuration: niri + ly + the GNOME shim
      #   plasma -- the KDE Plasma 6 evaluation: SDDM is the login manager, niri
      #             stays available in the session menu, the GNOME
      #             desktop-manager shim is dropped
      # Same hostName, same hardware, same user config -- the A/B is the desktop
      # layer only, and either output can be booted from GRUB's generation list.
      mkSystem = desktop: nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs system pkgs-unstable self desktop; };
        modules = [

          inputs.hermes-agent.nixosModules.default
          inputs.agenix.nixosModules.default
          ./modules/revision.nix
          ./host_chloe-laptop.nix
          ./modules/llm.nix
          ./modules/hermes.nix
          ./modules/cua-driver.nix
    
          home-manager.nixosModules.home-manager {
            
            home-manager.sharedModules = [
              inputs.nixcord.homeModules.nixcord
              inputs.stylix.homeModules.stylix
              ];
            
            home-manager.backupFileExtension = "__backup";
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
            home-manager.users.chloe = ./home/chloe.nix;
          }
        ];
      };
  in
  {
    nixosConfigurations = {
      chloe-laptop = mkSystem "niri";
      chloe-laptop-plasma = mkSystem "plasma";
    };
  };
}
