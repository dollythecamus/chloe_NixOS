{config, pkgs, pkgs-unstable, inputs, ...}:

{
  # Use the already-locked unstable pin for Godot alone; leave the main nixpkgs pin unchanged.
  home.packages = [
    pkgs-unstable.godot # 4.7.2-stable
    pkgs.scrcpy
    pkgs.android-tools
  ];

}
