{config, pkgs, inputs, ...} :

{
  wayland.windowManager.hyprland = {
    # Whether to enable Hyprland wayland compositor
    enable = true;
    # null because already defined in nixos
    package = null;
    portalPackage = null;
    # Whether to enable XWayland
    xwayland.enable = true;
    
    settings = {
    	
	monitor = ",preferred,auto,1";

	"$terminal" = "kitty fish";
	"$mod" = "SUPER";
	"$menu" = "wofi --show drun";
	"$fileManager" = "kitty yazi";

	exec-once = [
		"$terminal"

	];

	general = {
		gaps_in = 0;
		gaps_out = 0;
		border_size = 0;

		resize_on_border = true;
	};

	bind = [

	  "$mod, 1, workspace, 1"
	  "$mod, 2, workspace, 2"
	  "$mod, 3, workspace, 3"
	  "$mod, 4, workspace, 4"
	  "$mod, 5, workspace, 5"
	  "$mod, 6, workspace, 6"
	  "$mod, 7, workspace, 7"
	  "$mod, 8, workspace, 8"
	  "$mod, 9, workspace, 9"
	  "$mod, 0, workspace, 10"

	  "$mod, Q, exec, $terminal"
	  "$mod, F, exec, $fileManager"
	  "$mod, S, exec, $menu"
	  "$mod, C, killactive"
	];
    };

 };

}
