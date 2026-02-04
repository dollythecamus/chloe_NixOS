{config, pkgs, inputs, ...}:

{
    # stylix overwrites the settings.json that is annoying me, leave it without a theme is fine 
    stylix.targets.vscode.enable = false;
    
    programs.vscode = {
        enable = true;
        package = pkgs.vscode.fhs;
    };
}