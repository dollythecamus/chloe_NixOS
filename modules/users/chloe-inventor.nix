{ config, pkgs, inputs, ...}:

{

   users.users.chloe-inventor= {
      isNormalUser = true;
      description = "Dr. Chloe Inventor";
      extraGroups = [ "networkmanager" "wheel" "dialout" "bluetooth" "input"];
      packages = with pkgs; [
      
      # Gaming             
        prismlauncher
        ckan
        lutris
        wine

      # Mic
        discord
        qbittorrent
        drawpile 

      # Productivity
        obsidian
        libreoffice 
      
      # Creation
        krita
        godot
        #unstable.godot
        #unstable.godot-mono

        libresprite
        blender
        audacity
        lmms
        freecad
        inkscape 
        gimp 
        gmic-qt
        gmic
        pureref

      # Development
      	vscode
        github-desktop
      ];
  };
}
