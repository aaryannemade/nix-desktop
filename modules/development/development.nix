{ lib, platform, ... }:

{
  imports = [
    # shared (all platforms)
    ./_git-config.nix
    ./_neovim-config.nix
    ./_zed.nix
  ]
  ++ lib.optionals (platform == "nixos") [
  ]
  ++ lib.optionals (platform == "wsl") [
  ]
  ++ lib.optionals (platform == "darwin") [
  ];
}
