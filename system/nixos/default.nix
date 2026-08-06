{ ... }:

{
  imports = [
    ./bootloader.nix
    ./bluetooth.nix
    ./network.nix
    ./display.nix
    ./graphics-offload.nix
    ./sound.nix
    ./printing.nix
    ./authentication.nix
    ./virtualization.nix
    ./users.nix
    ./game-development.nix
    ./kernel.nix
    ./opendeck.nix
  ];

  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];
}
