{ config, lib, pkgs, ... }:

{
    boot.blacklistedKernelModules = [ "nouveau" ];
    
    nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
        "nvidia-x11"
        "nvidia-settings"
    ];
    
    services.xserver = {
        videoDrivers = [ "modesetting" "nvidia" ];
    };

    hardware.graphics.enable = true;
    
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
    
    # btop with CUDA support — overriding the global package so core/btop.nix picks it up automatically
    nixpkgs.config.packageOverrides = pkgs: {
        btop = pkgs.btop.override { cudaSupport = true; };
    };

    # Old approach: security wrapper with cap_perfmon for iGPU reading.
    # No longer needed since btop only reads the NVIDIA dGPU via NVML.
    # security.wrappers.btop = {
    #     owner = "root";
    #     group = "root";
    #     capabilities = "cap_perfmon+ep cap_dac_read_search+ep";
    #     source = "${pkgs.btop.override { cudaSupport = true; }}/bin/btop";
    # };
}