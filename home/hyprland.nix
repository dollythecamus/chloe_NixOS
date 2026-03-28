{config, pkgs, inputs, ...} :

{

  home.file.start = {
  	enable = true;
	executable = true;
	target = ".config/hypr/start.sh";
 	text = ''
	
	'';
  };

  home.file.toggle_eww = {
  	enable = true;
	executable = true;
	target = ".config/hypr/toggle_eww.sh";
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
	"$monitor" = "btop";

	exec-once = [
		"$terminal"
		"$fileManager"
		"kitty kew"
		"$monitor"
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
		border_size = 2;

		resize_on_border = true;

		#"col.active_border"   = "rgba(ffffffff)";
		#"col.inactive_border" = "rgba(ffffff00)";
		
		col = {
        	active_border = "rgba(ffffffff)";
     	 	inactive_border = "rgba(ffffff00)";
	    };
	};

	intermediate = {
    	  # This prevents ghost borders in some edge cases
    	  "no_focus_fallback" = true; 
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

	  "$mod SHIFT, 1, movetoworkspace, 1"
	  "$mod SHIFT, 2, movetoworkspace, 2"
	  "$mod SHIFT, 3, movetoworkspace, 3"
	  "$mod SHIFT, 4, movetoworkspace, 4"
	  "$mod SHIFT, 5, movetoworkspace, 5"
	  "$mod SHIFT, 6, movetoworkspace, 6"
	  "$mod SHIFT, 7, movetoworkspace, 7"
	  "$mod SHIFT, 8, movetoworkspace, 8"
	  "$mod SHIFT, 9, movetoworkspace, 9"
	  "$mod SHIFT, 0, movetoworkspace, 10"

	  "$mod, Q, exec, $terminal" 
	  "$mod, F, exec, $fileManager"
	  "$mod, S, exec, $menu"
	  "$mod, C, killactive"

	  "$mod, V, togglefloating"

	  ''$mod, PRINT, exec, grim -g "$(slurp)" - | wl-copy''
	  ''$mod SHIFT, PRINT, exec, grim -o eDP-1 - | wl-copy''

	
	];

	bindm = [
	  "$mod, mouse:272, movewindow"
	  "$mod, mouse:273, resizewindow"
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
