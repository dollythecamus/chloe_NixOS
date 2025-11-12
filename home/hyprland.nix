{config, pkgs, inputs, ...} :

{

  home.file.start = {
  	enable = true;
	executable = true;
	target = ".config/hypr/start.sh";
 	text = ''
	
	'';
  };

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
		"$fileManager"
		"kitty kew"
		"sh ./start.sh"
		"wpaperd"
	];

	input = {
		kb_layout = "us,br";
		kb_options = "grp:win_space_toggle";
	};

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

	  "$mod, V, togglefloating"
	];

	bindl = [
		", XF86AudioPrev, exec, playerctl previous"
		", XF86AudioPlay, exec, playerctl play-pause"
		", XF86AudioNext, exec, playerctl next"
		", XF86AudioPaue, exec, playerctl play-pause"
	];

	bindel = [
		" ,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
		",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
		",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
		",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
		",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
	];
    };
 };
}
