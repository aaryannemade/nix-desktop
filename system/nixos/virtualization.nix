{ username, ... }:

{
  # Native Docker daemon (NixOS-only). On macOS/Windows, use Docker Desktop on
  # the host and pipe into it; nix-darwin/WSL do not use this module.
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
    daemon.settings = {
      data-root = "/home/${username}/docker";
      userland-proxy = false;
      experimental = true;
      metrics-addr = "0.0.0.0:9329";
      ipv6 = false;
    };
  };
}
