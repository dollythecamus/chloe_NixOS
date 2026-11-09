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

        # Markdown preview settings. Font family/size for the preview come from
        # Stylix (markdown.preview.fontFamily / fontSize) — do not redefine them
        # here, a second plain definition of the same key is a module conflict.
        profiles.default.userSettings = {
            # Open .md as rendered preview instead of raw text. Reopen as text
            # with "Reopen Editor With…" or Ctrl+Shift+V from the text editor.
            # Remove this line if editing .md without that extra step is better.
            "workbench.editorAssociations"."*.md" = "vscode.markdown.preview.editor";

            # Single newlines become line breaks, matching Obsidian's reading view.
            "markdown.preview.breaks" = true;
            "markdown.preview.lineHeight" = 1.6;

            # Custom typesetting (measure, code blocks, tables, quotes).
            "markdown.styles" = [
                "${config.home.homeDirectory}/.config/Code/User/markdown-theme.css"
            ];
        };
    };

    xdg.configFile."Code/User/markdown-theme.css".source =
        ./dotfiles/config/Code/User/markdown-theme.css;
}
