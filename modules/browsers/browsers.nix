{ lib, platform, ... }:

{
  imports = [
    # shared (all platforms)
  ]
  ++ lib.optionals (platform == "nixos") [
    ./_helium.nix
    ./_librewolf.nix
  ]
  ++ lib.optionals (platform == "wsl") [
  ]
  ++ lib.optionals (platform == "darwin") [
  ];
}
