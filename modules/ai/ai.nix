{ lib, platform, ... }:

{
  imports = [
    # shared (all platforms)
    ./_claude.nix
    ./_opencode.nix
    ./_skills.nix
  ]
  ++ lib.optionals (platform == "nixos") [
  ]
  ++ lib.optionals (platform == "wsl") [
  ]
  ++ lib.optionals (platform == "darwin") [
  ];
}
