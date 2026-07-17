{config, pkgs, inputs, ...}:

{

  home.packages = with pkgs; [
    uutils-coreutils # Rust |> GNU core utils
    fd               # Rust |> better `find`
    bat              # Rust |> better `cat`
    eza              # Rust |> better `ls`
    zoxide           # Rust |> smarter `cd`
    gitui            # Rust |> git tui
    dust             # Rust |> pretty disk analyzer

    fzf        # fuzzy finder
    carapace   # completion
    
    terminaltexteffects
    fastfetch 
  ];
    
  programs.kitty.enable = true;
  
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };


  # tui file manager
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    settings = {
    };
  };

  # terminal shell = fish
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
# zoxide 
zoxide init fish | source

# fzf
fzf --fish | source

# carapace
set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
carapace _carapace | source

'';
    functions = {
      fish_greeting = {
        body = ''
echo "haiiiiiii :3 *paws u*"
'';
       };
       y = ''
set tmp (mktemp -t "yazi-cwd.XXXXXX")
yazi $argv --cwd-file="$tmp"
if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
builtin cd -- "$cwd"
	end
rm -f -- "$tmp"
''; 
       n = ''
kitty --directory (pwd) >/dev/null 2>&1 fish &
disown
'';
       matrix = ''
echo "i'll show you how deep the rabbit hole goes" | tte matrix
'';
    };
  };
}

