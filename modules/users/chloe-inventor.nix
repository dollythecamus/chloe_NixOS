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
        librewolf
	libreoffice 
      
      # Creation
        krita
        godot # 4.4
        # inputs.unstable_nixpkgs.pkgs.godot # 4.5
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
