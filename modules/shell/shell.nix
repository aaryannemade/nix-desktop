{ lib, platform, ... }:

{
  imports = [
    # shared (all platforms)
    ./_zsh.nix
    ./_zoxide.nix
    ./_fzf.nix
    ./_yazi.nix
    ./_ghostty.nix
    ./_ssh.nix
  ]
  ++ lib.optionals (platform == "nixos") [
  ]
  ++ lib.optionals (platform == "wsl") [
  ]
  ++ lib.optionals (platform == "darwin") [
  ];
}
