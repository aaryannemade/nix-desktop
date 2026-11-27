{ lib, platform, ... }:

{
  imports = [
    # shared (all platforms)
  ]
  ++ lib.optionals (platform == "nixos") [
    ./_filmcraft.nix
    ./_kdenlive.nix
    ./_davinci-resolve.nix
  ]
  ++ lib.optionals (platform == "wsl") [
  ]
  ++ lib.optionals (platform == "darwin") [
  ];
}
