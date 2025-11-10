{config, pkgs, inputs, ...} :

{
  home.packages = with pkgs; [
	eww;
  ];
  # i guess there is no way to acctually configure this with home-manager, kinda sad :| 
}
