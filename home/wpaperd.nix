{config, pkgs, inputs, ...}:

{
  services.wpaperd = {
    enable = true;
    settings = {
	eDP-1 = {
	  path = "</home/chloe/Mix/Media/Images/>";
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
