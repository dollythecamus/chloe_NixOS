{config, pkgs, inputs, ...}:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  	python313
	gnome-keyring
	jdk17_headless

    # dotnet 10 runtime, for playing KSA
    dotnetCorePackages.runtime_10_0-bin
  ];

  environment.variables = {
    # set the path of dotnet 10 runtime so that `steam-run` may use it 
    DOTNET_ROOT = "${pkgs.dotnet-runtime_10}";
    JAVA_HOME = "${pkgs.jdk17_headless}";
  };
  
}

