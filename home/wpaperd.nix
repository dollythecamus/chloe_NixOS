{config, pkgs, inputs, ...}:

{
  home.packages = [
  	pkgs.xaos
  ];

 
  # not used but. wanna use something like this
  home.file.gen-fractals = {
	enable = true;
	executable = true;
	target = ".config/wpaperd/gen_fractals.sh";
  	source = builtins.path {
   		 path = ./gen_fractals.sh;
    		 name = "gen_fractals";
  		};
  };

  services.wpaperd = {
    enable = true;
	
	settings = {
	  
	  eDP-1 = {
    	    path = "/home/chloe/.config/wpaperd/fractals/";
    	    apply-shadow = true;
	    recursive = true;
	    mode = "center";
	    sorting = "random";
	    duration = "30m";
	    transition-time = 0;
	    exec = "/home/chloe/.config/wpaperd/gen_fractals.sh";
	  };

	};

  };

}
