{ lib, platform, ... }:

{
  imports = [
    # shared (all platforms)
    ./_opencode.nix
  ]
  ++ lib.optionals (platform == "nixos") [
  ]
  ++ lib.optionals (platform == "wsl") [
  ]
  ++ lib.optionals (platform == "darwin") [
  ];
}
