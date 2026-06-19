{ username, ... }:

{
  # NixOS-WSL system config.
  # Cherry-pick shared NixOS modules as needed, e.g.:
  #   imports = [ ../nixos/network.nix ];
  imports = [
    ./users.nix
    ./kernel.nix
    ./graphics.nix
    ./systemd.nix
  ];

  # Core NixOS-WSL switch. Provides the WSL boot/init layer and the
  # Windows<->Linux interop. `defaultUser` is the user `wsl.exe` logs in as.
  wsl = {
    enable = true;
    defaultUser = username;

    # Expose Windows-side tooling on PATH (docker.exe, code, etc.) and let
    # Windows interop start Linux GUI apps via WSLg.
    interop.includePath = true;
    startMenuLaunchers = true;
  };
}
