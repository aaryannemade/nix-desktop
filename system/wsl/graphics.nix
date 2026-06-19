{ lib, ... }:

{
  # GPU support under WSL is fundamentally different from a bare-metal NixOS
  # host: there is NO nvidia kernel module, NO PRIME offload, and NO X server.
  # The Windows host driver is bind-mounted into the WSL distro at
  # /usr/lib/wsl/lib (libcuda, libnvidia-*, d3d12 mesa, etc.) and exposed via
  # the /dev/dxg device. NixOS-WSL wires this up when `wsl.enable = true`.
  #
  # This module only enables the userspace graphics stack (loaders) so
  # OpenGL/Vulkan/CUDA apps can find the passthrough libraries. The CUDA
  # *package* overrides live in the per-host graphics.nix, matching the phantom
  # split.

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Make the WSL-mounted Windows driver libraries discoverable to dynamically
  # linked CUDA/Vulkan apps. NixOS-WSL adds /usr/lib/wsl/lib to the loader path,
  # but exporting LD_LIBRARY_PATH helps non-patchelf'd CUDA binaries find
  # libcuda.so. Scope it narrowly to avoid clobbering the Nix store loader.
  environment.sessionVariables = {
    LD_LIBRARY_PATH = lib.mkDefault "/usr/lib/wsl/lib";
  };
}
