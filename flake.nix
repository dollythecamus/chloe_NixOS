{
  description = "Chloe's NixOS Configuration Flake";

  inputs = {
    
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Blender is pinned to its OWN nixpkgs input (2026-10-22) on purpose.
    # blender.override { cudaSupport = true; } produces a derivation that is
    # never on cache.nixos.org (Hydra only builds the default cudaSupport=false
    # variant -- narinfo for the live output returns 404), so it compiles
    # locally, which on this laptop is hours. If it rode the `nixpkgs` pin,
    # every `nix flake update nixpkgs` would force that full rebuild.
    # Bumping this input is the deliberate act that pays the cost; keep the
    # flake update targeted: `nix flake update nixpkgs`, never a bare
    # `nix flake update`. Locked at the rev blender 5.1.1 was built from.
    nixpkgs-blender.url = "github:NixOS/nixpkgs/fd1462031fdee08f65fd0b4c6b64e22239a77870";

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

      # Daily driver (2026-10-14): GNOME + GDM on chloe-laptop -- the simplest
      # stack that just works, owning the desktop entirely. ly + niri remain
      # the login manager and recovery session of the two A/B fallback
      # outputs (chloe-laptop-niri, chloe-laptop-plasma), byte-identical to
      # the adopted era. The "sway-prototype" desktop value is gone from this
      # flake alongside the reverted adoption (revert commit d037b73 on main).
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
            home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable desktop; };
            # Arm by desktop: the homie file branches on `desktop` from
            # extraSpecialArgs (gnome/niri/plasma).
            home-manager.users.chloe = ./home/chloe.desktop.nix;
          }
        ];
      };
  in
  {
    nixosConfigurations = {
      chloe-laptop = mkSystem "gnome";
      chloe-laptop-niri = mkSystem "niri";
      chloe-laptop-plasma = mkSystem "plasma";
    };
  };
}
