{ lib, platform, ... }:

{
  imports = [
    # shared (all platforms)
  ]
  ++ lib.optionals (platform == "nixos") [
    ./_mpv.nix
  ]
  ++ lib.optionals (platform == "wsl") [
  ]
  ++ lib.optionals (platform == "darwin") [
  ];
}
