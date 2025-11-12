{config, pkgs, inputs, ...}:

{
  services.wpaperd = {
    enable = true;
    settings = {
        display = {
	  path = "/home/chloe/Mix/Media/Images/";
	};
	
	eDP-1 = {
	  recursive = true;
	  sorting = "random";
	  duration = "835msec"; 
	  # for 60 FPS, each image has 5 frames 
	  transition-time = "0";
	  mode = "center";
	};
    }; 


  };

}
