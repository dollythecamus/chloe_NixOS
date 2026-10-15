{config, pkgs, ...}:

{
  home.packages = with pkgs; [ 
    prismlauncher   # modded minecraft 
    ckan            # modded kerbal space program
    lutris          # wine / proton library
    espeak-ng       # terminal-vtuber robotic TTS
  ];
}
