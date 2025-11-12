{config, pkgs, inputs, ...}:

{
  home.packages = [
	pkgs.haskellPackages.fractal
  ];
  

  home.file.gen-fractals = {
	enable = true;
	executable = true;
	target = ".config/wpaperd/gen_fractals.sh";
  	source = "/home/chloe/NixOS/home/gen_fractals.sh";
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
	    duration = "2sec";
	    transition-time = 0;
	    exec = "/home/chloe/.config/wpaperd/gen_fractals.sh";
	  };

	};

  };

}
