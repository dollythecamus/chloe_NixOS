{config, pkgs, inputs, ...}:

{
  services.wpaperd = {
    enable = true;
    settings = {
	default = {
	  path = "${HOME}/Mix/Media/Images/";
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
