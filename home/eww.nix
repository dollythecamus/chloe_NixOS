{config, pkgs, inputs, ...} :

{
  # EWW STUFF I WANT:

  # time, date, calendar
  # battery
  # workspaces
  # power 
  # audio

  # yay !
  # it these are the building blocks basically
  home.file = {
    yuck = {
	enable = true;
	target = ".config/eww/eww.yuck";
  	source = builtins.path {
   		 path = ./eww/eww.yuck;
    		 name = "eww_yuck";
  		};
    };
    
    yuckvar = {
	enable = true;
	target = ".config/eww/eww_variables.yuck";
  	source = builtins.path {
   		 path = ./eww/eww_variables.yuck;
    		 name = "ewwvariables_yuck";
  		};
    };

    yuckwid = {
	enable = true;
	target = ".config/eww/eww_widgets.yuck";
  	source = builtins.path {
   		 path = ./eww/eww_widgets.yuck;
    		 name = "eww_widgets_yuck";
  		};
    };

    yuckwin = {
	enable = true;
	target = ".config/eww/eww_windowsyuck";
  	source = builtins.path {
   		 path = ./eww/eww_windows.yuck;
    		 name = "eww_window_yuck";
  		};
    };

    sh_search = {
	enable = true;
	executable = true;
	target = ".config/eww/scripts/search.sh";
  	source = builtins.path {
   		 path = ./eww/scripts/search.sh;
    		 name = "eww_sh_search";
  		};
    };

    sh_airplane = {
	enable = true;
	executable = true;
	target = ".config/eww/scripts/airplane_mode.sh";
  	source = builtins.path {
   		 path = ./eww/scripts/airplane_mode.sh;
    		 name = "eww_sh_airplane";
  		};
    };

    sh_screenshot = {
	enable = true;
	executable = true;
	target = ".config/eww/scripts/screenshot.sh";
  	source = builtins.path {
   		 path = ./eww/scripts/screenshot.sh;
    		 name = "eww_sh_screenshot";
  		};
     };
  }; 
  

  programs.eww = {
	enable = true;
	enableFishIntegration = true;
  };
    # i guess there is no way to acctually configure this with home-manager, kinda sad :| 
}
