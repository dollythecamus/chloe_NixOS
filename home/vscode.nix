{config, pkgs, inputs, ...}:

{
    programs.vscode = {
        enable = true;
        package = pkgs.vscode-fhs;
    };
}
