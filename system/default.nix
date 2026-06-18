{ lib, platform, ... }:

{
  # Platform dispatcher: import shared system config plus the modules
  # for this host's platform. `platform` is set per-host in hosts/default.nix.
  imports =
    [ ./shared ]
    ++ lib.optional (platform == "nixos") ./nixos
    ++ lib.optional (platform == "wsl") ./wsl
    ++ lib.optional (platform == "darwin") ./darwin;
}
