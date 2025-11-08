{ config, pkgs, inputs, ...}:

{

   users.users.chloe-inventor= {
      isNormalUser = true;
      description = "Dr. Chloe Inventor";
      extraGroups = [ "networkmanager" "wheel" "dialout" "bluetooth" "input"];
      packages = with pkgs; [
      # Gaming  ddd              
        prismlauncher
        ckan
        lutris
        wine

      # Mic
        discord
        qbittorrent
        element-desktop
        drawpile # collaborative drawing :3

      # Productivity
        obsidian
        libreoffice # office pack
      
      # Creation
        polyphone
        krita
        godot # godot with Orchestrator
        #unstable.godot
        #unstable.godot-mono

        libresprite

        librewolf

        blender
        audacity
        lmms
        # reaper # sound design # it is NOT FREE ! OH NO !
        freecad
        inkscape # FOSS Vector Graphics
        gimp # FOSS Image Editor
        gmic-qt
        gmic
        # unstable.cura-appimage # Ultimaker Cura for 3D prints
          # seems to screw up nixos rebuild as well as cudatoolkit
        pureref

      # Development
        thonny # rpi pico dev
      	vscode # VSCode!
        github-desktop
      ];
  };
}
