{config, pkgs, inputs, ...}:

{
    nixpkgs.config.allowUnfree = true;

    programs.vscode = {
        enable = true;
        package = pkgs.vscode-fhs;
    };
}
