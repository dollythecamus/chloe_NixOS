{config, pkgs, pkgs-unstable, inputs, ...}:

{
  # install godot
  environment.systemPackages = with pkgs; [
    godot # 4.5 
    pkgs-unstable.godot # 4.6.3 most recent
    
    # for android work
    scrcpy
    android-tools
  ];

  # programs.adb.enable = true;

}
