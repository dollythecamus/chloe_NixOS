{config, pkgs, inputs, ...}:

{

  services.wpaperd = {
    enable = true;
	
	settings = {
	  
	  eDP-1 = {
    	    path = "/home/chloe/Mix/Media/Images/";
    	    apply-shadow = true;
	    recursive = true;
	    mode = "center";
	    sorting = "random";
	    duration = "0167msec";
	    transition-time = 0;
	  };

	};

  };

}
