{config, pkgs-unstable, ...}:

{
  programs.aider-chat = {
    enable = true;
    package = pkgs-unstable.aider-chat;
  };
}
