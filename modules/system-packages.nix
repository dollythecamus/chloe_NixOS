{config, pkgs, inputs, ...}:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [

    # oxidise - Rust packages
    uutils-coreutils # GNU coreutils
    fish # command line shell
    # nushell # another command line shell
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
    #unstable.ncspot # spotify, but awesome # unstable because it is broken in stable
    rusty-man # rust docs in cli
    wiki-tui # wikipedia in cli! how queer!
    mask # command runner in a markdown file, woa
    presenterm # terminal slides presentation tool 

    # need some
    killall

    # Hyprland 
    kitty
    waybar
    dunst
    wofi
    sway
    nwg-look
    swww

    wl-clipboard # copy paste features
    
    playerctl # control media player
    brightnessctl # control brighness
    
    hyprpolkitagent
    hyprlock
    
    networkmanager
    #qt5-wayland
    #qt6-wayland
    input-remapper # to use the cool mouse that doesn't work but looks cool

  # Misc
    adwaita-icon-theme # Adwaita icon theme
    font-awesome # font awesome for waybar icons 
    neocities # for working with my neocities website  
    neofetch
    neovim
    
    wacomtablet # drawing tablet
    
    ffmpeg # media converter uwu
    yt-dlp # youtube video downloader
    vlc # video player
    
    python313

    grim # for screenshots
    slurp # also

    cudatoolkit # CUDA hardware acceleration, blender as well as Ollama
  ];
}

