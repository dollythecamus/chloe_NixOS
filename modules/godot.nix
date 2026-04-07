{config, pkgs, pkgs-unstable, inputs, ...}:

{
  environment.systemPackages = [
    pkgs.godot # 4.5 
    pkgs-unstable.godot # 4.6.1
    
    pkgs.srcpy
  ];

  programs.adb.enable = true;

}
