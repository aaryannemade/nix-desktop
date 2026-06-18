{ lib, platform, ... }:

{
  imports =
    [
      # shared (all platforms)
    ]
    ++ lib.optionals (platform == "nixos") [
      ./_bluetooth-ui.nix
      ./_obs.nix
    ]
    ++ lib.optionals (platform == "wsl") [
    ]
    ++ lib.optionals (platform == "darwin") [
    ];
}
