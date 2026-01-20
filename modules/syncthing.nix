#syncthing nix module :)

{config, pkgs, inputs, ...}:

{
  services.syncthing = {
    enable = true;
    settings = {
      # Define all your devices here using their actual Syncthing Device IDs
      devices = {
        "amanita-mobile" = {
          id = "W54WQWG-B4EPE7H-F5WYUHX-FB3OMKO-GZHUCHS-NQXEFIG-KXMIQBX-CJIEDA3"; 
        };

        # "portable-chloe" = {
        #   id = "undefined"; # undefined -- has to be inserted here later.
        # };
        # Add more devices as needed
      };

      # Define all shared folders here

      folders = {
        "Media" = {
          path = "~/Mix/Media";
          devices = ["amanita-mobile"];
        };

        "Mind" = {
          path = "~/Mix/Mind";
          devices = ["amanita-mobile"];
        };

        "Inventions" = {
          path = "~/Mix/Inventions";
          devices = ["amanita-mobile"];
        };

        "College" = {
          path = "~/Mix/College";
          devices = ["amanita-mobile"];
        };

      };
    };
  };


}

