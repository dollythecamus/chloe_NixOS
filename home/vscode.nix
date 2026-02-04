{config, pkgs, inputs, ...}:

{
    stylix.targets.vscode.enable = true;
    
    programs.vscode = {
        enable = true;
        package = pkgs.vscode.fhs;
    };
}