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
  ];
    
  programs.kitty.enable = true;
  
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # GitHub CLI: gh. config.yml is HM-owned (read-only in the store), so
  # every preference gh needs must be declared here — `gh config set`
  # cannot write it. Auth state (hosts.yml, token in the keyring) stays
  # runtime-owned so `gh auth login/refresh/switch` keep working.
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh"; # matches hosts.yml; ~/.ssh/id_ed25519_github
      editor = "nvim"; # matches EDITOR in modules/programs.nix
      prompt = "enabled";
    };
    # HM's default (true) only writes the gh git credential helper when
    # HM `programs.git` is enabled; git here is system-wide
    # (modules/programs.nix, libsecret helper), so it would be inert.
    gitCredentialHelper.enable = false;
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
       # system maintenance automation (source in repo: home/fish/)
       rebuild = builtins.readFile ./fish/rebuild.fish;
    };
  };
}

