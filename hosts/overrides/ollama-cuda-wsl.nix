{ lib, ... }:

# WSL-only companion to ollama-cuda.nix. Under WSL the NVIDIA driver libraries
# live at /usr/lib/wsl/lib (GPU passthrough), so the ollama service must be
# pointed there in addition to the standard OpenGL driver path. On native NixOS
# hosts /run/opengl-driver/lib is enough and this file is not imported.
{
  systemd.services.ollama.environment.LD_LIBRARY_PATH =
    lib.mkForce "/usr/lib/wsl/lib:/run/opengl-driver/lib";
}
