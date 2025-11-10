{config, pkgs, inputs, ...}:

{
  programs.fish = {
	enable = true;  
	interactiveShellInit = ''
     		set fish_greeting # Disable greeting
		neofetch
  	'';
  };

}

