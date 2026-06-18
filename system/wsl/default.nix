{ ... }:

{
  # NixOS-WSL system config goes here.
  # Cherry-pick shared NixOS modules as needed, e.g.:
  #   imports = [ ../nixos/network.nix ];
  imports = [
    ./users.nix
  ];
}
