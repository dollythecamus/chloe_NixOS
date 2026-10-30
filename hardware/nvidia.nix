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
    #
    # 2026-10-29: off, because this laptop has no iGPU to hand the panel to
    # (see the prime block below) and nixpkgs asserts finegrained == offload
    # enabled. Runtime powering-down of the only display GPU is not a state
    # that can work here: the panel is wired to the RTX 3050.
    powerManagement.finegrained = false;

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

  # prime is laptop specific — and NOT this laptop's current GPU state.
  #
  # 2026-10-29: PRIME offload is off because the headless iGPU it assumes does
  # not exist here. With offload enabled and amdgpuBusId = PCI:54:0:0 the
  # generated xorg.conf had a single Screen backed by Device-amdgpu[0]
  # (BusID PCI:54:0:0) and the NVIDIA card only as an offload GPUDevice:
  #
  #   ServerLayout "Layout[all]"  ->  Screen "Screen-amdgpu[0]"
  #   Device "Device-amdgpu[0]"      Driver "amdgpu"  BusID "PCI:54:0:0"
  #   Device "Device-nvidia[0]"      Driver "nvidia"  BusID "PCI:1:0:0"  (GPUDevice)
  #
  # Measured on the running machine: exactly one graphics function exists —
  # 0000:01:00.0, 10de:25ec, driver nvidia — and /dev/dri holds only
  # card1/renderD128. There is no AMD VGA function at all (the only AMD device
  # is 0000:05:00.0, class 0x130000, the Sensor Fusion Hub; note it is nowhere
  # near 54:0:0). So the X server had no usable screen: the first X11 session
  # this host ever ran (XFCE, generation 116, boot 2026-10-29 21:28) got 8 s
  # past ly's greeter and came straight back. Wayland outputs never read
  # xorg.conf, which is why GNOME/niri/Plasma were fine all along.
  #
  # With offload disabled, services.xserver.drivers is the NVIDIA entry alone
  # with display = true, i.e. one Device/Screen driven by the RTX 3050 — what
  # Wayland already does for this panel. Restore the block with the *real* bus
  # IDs if the firmware MUX is ever switched back to hybrid graphics.
  hardware.nvidia.prime = {
    offload.enable = false;
    offload.enableOffloadCmd = false;
    nvidiaBusId = "PCI:1:0:0";
    amdgpuBusId = ""; # iGPU absent; PCI:54:0:0 was never this machine's bus
  };

# End of Nvidia Configuration
}
