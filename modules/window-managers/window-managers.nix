{ lib, platform, ... }:

{
  imports =
    [
      # shared (all platforms)
    ]
    ++ lib.optionals (platform == "nixos") [
      ./_mangowm.nix
      ./_noctalia-shell.nix
    ]
    ++ lib.optionals (platform == "wsl") [
    ]
    ++ lib.optionals (platform == "darwin") [
    ];
}
