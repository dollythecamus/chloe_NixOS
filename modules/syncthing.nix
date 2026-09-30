#syncthing nix module :)

{config, pkgs, inputs, ...}:

{
  services.syncthing = {
    enable = true;
    settings = {
      # Define all your devices here using their actual Syncthing Device IDs
      devices = {
        "chloe-mobile" = {
          id = "W54WQWG-B4EPE7H-F5WYUHX-FB3OMKO-GZHUCHS-NQXEFIG-KXMIQBX-CJIEDA3"; 
        };
        # Add more devices as needed
      };

      # Define all shared folders here
      folders = {
        "Mind" = {
          path = "~/Mind";
          devices = ["amanita-mobile"];
          versioning = {
            type = "trashcan"; # Options: "simple", "staggered", "trashcan", "external", ""
          };
        };
      };
    };
  };
}

