{config, pkgs, inputs, ...}:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    python313
    nodejs_22
    (pkgs.callPackage ../pkgs/lightpanda.nix { })
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.agent-browser
    gnome-keyring
    jdk17_headless
    dotnetCorePackages.runtime_10_0-bin
  ];

  environment.variables = {
    # dotnet 10 SDK + runtime under one root: the SDK (used by VS Code's C#
    # tooling) must resolve here, the runtime keeps steam-run fed. DOTNET_ROOT
    # must name a directory that CONTAINS the SDK's `sdk/` subdir — pointing
    # it at the runtime-only package leaves `dotnet` reporting sdk-not-found.
    # Environment variables hold strings, so combinePackages must be
    # interpolated here (concat a file) and combined removal belongs to the
    # program module: vscode-fhsWithPackages pulls the SDK into the IDE.
    DOTNET_ROOT = "${pkgs.dotnetCorePackages.combinePackages [
      pkgs.dotnetCorePackages.sdk_10_0
      pkgs.dotnetCorePackages.runtime_10_0-bin
    ]}/share/dotnet";
    JAVA_HOME = "${pkgs.jdk17_headless}";
  };
  
}

