{config, pkgs, ...}:

# not used currently
{
    # unity for gamedev
    # used to be installed with flatpak but it is giving me problems
    
    # https://huantian.dev/blog/unity3d-rider-nixos/
    # some help

    home.systemPackages = with pkgs; [
        # install unity hub
        unityhub
        
        # install jetbrains rider
        rider
    ];
}