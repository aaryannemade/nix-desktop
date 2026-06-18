{ lib, platform, ... }:

{
  imports = [
    # shared (all platforms)
    ./_top.nix
  ]
  ++ lib.optionals (platform == "nixos") [
  ]
  ++ lib.optionals (platform == "wsl") [
  ]
  ++ lib.optionals (platform == "darwin") [
  ];
}
