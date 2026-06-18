{ ... }:

{
  imports = [
    ./bootloader.nix
    ./bluetooth.nix
    ./network.nix
    ./display.nix
    ./sound.nix
    ./printing.nix
    ./authentication.nix
    ./virtualization.nix
    ./users.nix
    ./game-development.nix
  ];
}
