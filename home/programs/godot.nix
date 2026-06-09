{config, pkgs, pkgs-unstable, inputs, ...}:

{
  # install godot
  home.packages = with pkgs; [
    godot # 4.6
    # with recent nixpkgs update, godot is available
    # pkgs-unstable.godot # 4.6.3 most recent
    
    # for android work
    scrcpy
    android-tools
  ];

}
