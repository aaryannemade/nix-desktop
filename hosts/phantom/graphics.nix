{ config, lib, pkgs, ... }:

{
    boot.blacklistedKernelModules = [ "nouveau" ];
    
    nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
        "nvidia-x11"
        "nvidia-settings"
        "cuda_cudart"
        "cuda_nvcc"
        "cuda_cccl"
        "libcublas"
        "steam"
        "steam-unwrapped"
        "blender"
    ];
    
    # Override btop globally so core/system-monitoring.nix installs the CUDA version.
    nixpkgs.config.packageOverrides = pkgs: {
        btop = pkgs.btop.override { cudaSupport = true; };
        blender = pkgs.blender.override { cudaSupport = true; };
    };

    # Enable Cuda Cache
    nix.settings = {
      substituters = [
        "https://cache.nixos-cuda.org"
      ];
      trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      ];
    };

    # Security wrapper so btop can read the Intel iGPU performance counters.
    security.wrappers.btop = {
        owner = "root";
        group = "root";
        capabilities = "cap_perfmon+ep cap_dac_read_search+ep";
        source = "${pkgs.btop}/bin/btop";
    };

    services.xserver = {
        videoDrivers = [ "modesetting" "nvidia" ];
    };

    # Enable Cuda for Ollama
    services.ollama.package = pkgs.ollama-cuda;

    hardware.graphics.enable = true;
    
    hardware.graphics.enable32Bit = true;

    hardware.nvidia = {
        modesetting.enable = true;

        powerManagement.enable = false;
        powerManagement.finegrained = false;

        open = true;
        nvidiaSettings = true;

        package = config.boot.kernelPackages.nvidiaPackages.stable;

        prime = {
            offload = {
                enable = true;
                enableOffloadCmd = true;
            };
      
            intelBusId = "PCI:0:2:0";
            nvidiaBusId = "PCI:1:0:0";
        };
    };
    
}
