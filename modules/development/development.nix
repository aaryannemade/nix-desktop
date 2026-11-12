{ lib, platform, ... }:

{
  imports = [
    # shared (all platforms)
    ./_git-config.nix
    ./_hellish-mcp.nix
    ./_herdr.nix
    ./_neovim-config.nix
  ]
  ++ lib.optionals (platform == "nixos") [
    ./_blender-mcp.nix
    ./_playwright.nix
  ]
  ++ lib.optionals (platform == "wsl") [
  ]
  ++ lib.optionals (platform == "darwin") [
  ];
}
