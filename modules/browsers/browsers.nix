{ lib, platform, ... }:

{
  imports =
    [
      # shared (all platforms)
    ]
    ++ lib.optionals (platform == "nixos") [
      ./_librewolf.nix
    ]
    ++ lib.optionals (platform == "wsl") [
    ]
    ++ lib.optionals (platform == "darwin") [
    ];
}
