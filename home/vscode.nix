{config, pkgs, inputs, ...}:

{
    nixpkgs.config.allowUnfree = true;

    programs.vscode = {
        enable = true;
        # Wrapped variant which inherits the session environment (VS Code C#
        # tooling needs DOTNET_ROOT from /etc/pam/environment, which the
        # bubblewrap wrapper propagates) and carries the .NET SDK inside the
        # FHS root: the extension host resolves `dotnet` against the rootfs
        # /nix profile + bin PATH, so the SDK must be installed into the
        # wrapper itself for C#/OmniSharp to find a build toolchain.
        package = pkgs.vscode-fhsWithPackages (ps: [
            pkgs.dotnetCorePackages.sdk_10_0
        ]);
    };
}
