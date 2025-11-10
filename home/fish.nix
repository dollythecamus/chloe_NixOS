{config, pkgs, inputs, ...}:

{
  programs.fish = {
	enable = true;
	interactiveShellInit = ''
	zoxide init fish | source
	neofetch | tte blackhole
	'';

	functions = {
		fish_greeting = {
		body = ''echo "haiiiiiii :3 *paws u*"'';
		};
	};
	
  };
}

