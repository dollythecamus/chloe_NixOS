{config, pkgs, pkgs-unstable, inputs, ...}:

{
  programs.nixcord = {
    enable = true;
    vesktop.enable = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.kitty.enable = true;
  
  home.packages = with pkgs; [
    
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

        neofetch
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
	pkgs-unstable.wiki-tui # wikipedia in cli! how queer!
        
	mask # command runner in a markdown file, woa
        presenterm # terminal slides presentation tool
        #ncspot # spotify but good
        kew # music player

        prismlauncher
        ckan
        lutris
        wine

        qbittorrent
        drawpile 

        obsidian
        librewolf
	libreoffice 
      
        krita
        godot # 4.5
	#pkgs-unstable.godot # latest 4.6.2

        libresprite
        blender
        audacity
        lmms
        freecad
        inkscape 
        gimp 
        gmic-qt
        gmic
        pureref

        github-desktop # could install via flatpak to solve some issues, let's see
  
  ];

}
