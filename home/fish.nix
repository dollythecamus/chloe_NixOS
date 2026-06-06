{config, pkgs, inputs, ...}:

{
  programs.fish = {
	enable = true;
	interactiveShellInit = ''
	zoxide init fish | source
	'';

	functions = {

		fish_greeting = {
		body = ''
		  echo "haiiiiiii :3 *paws u*"
		  '';
		};

		/*
		y = {
		body = ''
			set tmp (mktemp -t "yazi-cwd.XXXXXX")
			yazi $argv --cwd-file="$tmp"
			if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
				builtin cd -- "$cwd"
			end
			rm -f -- "$tmp"
			''; 
		};

		n = {
		body = ''
    		kitty --directory (pwd) >/dev/null 2>&1 fish &
    		disown
			'';
		};

		matrix = {
		  body = ''
		    echo "i'll show you how deep the rabbit hole goes" | tte matrix
			'';
	    };
		*/
	};
  };
}

