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

    # Pi (pi.dev) — a second agent harness next to hermes-agent, for the case
    # where the agent loop itself is the thing being authored (TypeScript
    # extensions, RPC, SDK). Not a replacement: hermes keeps the gateway,
    # memory, cron and delegation surfaces.
    # Pinned to the COMMIT 818c42cd, not to the v1.5.0 tag. Two upstream
    # packaging bugs make the tag unbuildable, both fixed within two days of it
    # and both invisible until `nix build` runs:
    #   1. v1.5.0's nix/package.nix overrides seven internal packages in
    #      `packageSourceOverrides` while its install lock carries eight, so
    #      `@earendil-works/pi-schema` was fetched with no integrity hash →
    #      "attribute 'integrity' missing" at evaluation time. Fixed in d71c66e0
    #      (2026-11-03, "fix(nix): pack pi-schema for the install lock").
    #   2. The Nix build hydrates its model catalog from the revision pinned in
    #      nix/model-catalog.json, offline. v1.5.0's pin predates the classifier
    #      models, so `pi-ai` failed tsc on github-copilot.ts ("Type 'unknown[]'
    #      is not assignable to readonly ProviderModel[]") after ~4 minutes of
    #      building. Refreshed in a57438e9 / 818c42cd (2026-11-03/04).
    # 818c42cd is the newest catalog-pin refresh and still reports 1.5.0.
    # Bump this to the next release tag once upstream ships one containing both
    # fixes; the catalog pin is what makes a tag self-contained.
    # nixpkgs follows the unstable pin so pi builds against the node/npm already
    # locked here rather than importing a second nixpkgs tree.
    # A pin is needed at all because nixpkgs lags badly: on 2026-11-08 the
    # stable nixpkgs pin carried 0.75.4 and the unstable input 0.87.1.
    pi = {
      url = "github:earendil-works/pi/818c42cdeb1b";
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
            # extraSpecialArgs (gnome/niri/plasma/xfce).
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
      chloe-laptop-xfce = mkSystem "xfce";
    };
  };
}
