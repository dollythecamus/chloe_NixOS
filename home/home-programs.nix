{config, pkgs, pkgs-unstable, inputs, ...}:

{
  imports = [
        ./programs/unity.nix
        ./programs/godot.nix
        ./programs/blender.nix
  ];

  programs.nixcord = {
    enable = true;
    vesktop.enable = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.obsidian = {
    enable = true;
    cli.enable = true;
  };

  programs.kitty.enable = true;
  
  home.packages = with pkgs; [
    home-manager # make home-manager available for use in the terminal
    
    # rice
	terminaltexteffects # cool
        fish
        wofi
	nvtopPackages.nvidia
        base16-schemes

        playerctl
        brightnessctl
        grim
        slurp
        glow

	pkgs-unstable.btop-cuda
	nvtopPackages.nvidia

	fastfetch
        neocities
        vlc
        wl-clipboard
        adwaita-icon-theme
        font-awesome
	nautilus
	peaclock
	
        uutils-coreutils # GNU coreutils
        fish # command line shell
        fd # alternative to find
        bat # cat, but better (idk what cat is
        eza # alternative to ls
        zoxide # smarter cd
        zellij # interesting ui
        gitui # git ui 
        dust # pretty disk analyzer
        starship # customizeable prompts for any shell
        yazi # interesting file manager
        bacon # rust compiler
        cargo-info # get data about rust packages from the internet without going through the browser
        rusty-man # rust docs in cli

        # it seemed that stable was bad for wiki-tui idk why
        
	mask # command runner in a markdown file, woa
        presenterm # terminal slides presentation tool
        kew # music player

        # gaming
        prismlauncher
        ckan
        lutris

        # torrent
        qbittorrent

        # browser, office
        librewolf
	libreoffice 
      
        # art
        krita
        gimp 

        # music
        lmms

        # dev
        github-desktop
  ];

}
