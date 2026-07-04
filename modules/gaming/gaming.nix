{ lib, platform, ... }:

{
  imports = [
    # shared (all platforms)
  ]
  ++ lib.optionals (platform == "nixos") [
    ./_gamescope.nix
    ./_mangohud.nix
    ./_proton.nix
  ]
  ++ lib.optionals (platform == "wsl") [
  ]
  ++ lib.optionals (platform == "darwin") [
  ];
}
