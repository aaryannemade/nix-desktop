{ lib, hostname, ... }:

let
  # Hosts that should use NVIDIA PRIME offload: render on the iGPU by default
  # and offload to the dGPU on demand. Only laptop/mobile hosts belong here —
  # desktops (e.g. wraith) should drive everything from the dGPU even if an
  # iGPU is present. Extend this map when adding a new laptop host; bus IDs
  # come from `lspci` (hex) converted to decimal, e.g. 00:02.0 -> PCI:0:2:0.
  offloadHosts = {
    phantom = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
in
{
  hardware.nvidia.prime = lib.mkIf (offloadHosts ? ${hostname}) {
    offload = {
      enable = true;
      enableOffloadCmd = true;
    };

    inherit (offloadHosts.${hostname}) intelBusId nvidiaBusId;
  };
}
