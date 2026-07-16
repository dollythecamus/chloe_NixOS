{config, ...}:

{
  home.packages = with pkgs; [ 
    prismlauncher   # modded minecraft 
    ckan            # modded kerbal space program
    lutris          # wine / proton library
  ];
}
