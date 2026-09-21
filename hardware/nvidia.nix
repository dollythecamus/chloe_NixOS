{config, inputs, pkgs, ...}:

{
  # Nvidia Configuration

  # Enable OpenGL
  #
  # extraPackages: the OpenCL ICD *loader* (libOpenCL.so.1). The NVIDIA driver
  # ships only the vendor ICD (libnvidia-opencl.so.1 + /run/opengl-driver/etc/
  # OpenCL/vendors/nvidia.icd); the vendor-neutral loader comes from pkgs.ocl-icd.
  # With nothing providing it, Unity's GPU lightmapper backend
  # (Editor/Data/Tools/libRadeonRays.so, a hard dynamic dependency on
  # libOpenCL.so.1) failed to load and the editor logged "Light baking could not
  # be started because no valid OpenCL device could be found" despite a working
  # CUDA OpenCL platform. ocl-icd is built with
  # --enable-custom-vendordir=/run/opengl-driver/etc/OpenCL/vendors, so its default
  # vendor search path is already the populated NixOS one — no OCL_ICD_VENDORS,
  # no OPENCL_VENDOR_PATH, and no unityhub override are needed.
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.ocl-icd ];
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia-container-toolkit.enable = true;

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer). (includes my RTX 3050)
    powerManagement.finegrained = true;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    open = true; # i think unity engine is complaining about the open driver
                 # how entitled

    # Enable the Nvidia settings menu,
	  # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # prime is laptop specific
  hardware.nvidia.prime = {
	  offload = {
      enable = true;
      enableOffloadCmd = true;
	  };
	  nvidiaBusId = "PCI:1:0:0";
	  amdgpuBusId = "PCI:54:0:0";

  };

# End of Nvidia Configuration
}
