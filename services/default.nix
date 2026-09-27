{ platform, ... }:

# On-demand, user-space services (rootless podman etc.), dispatched by
# platform like ../system/default.nix. Every host imports this directory
# (via ../configuration.nix); only its platform's services are pulled in.
# `platform` is set per-host in hosts/default.nix.
let
  servicesByPlatform = {
    nixos = [
      ./vpn-browser
    ];
    wsl = [ ];
    darwin = [ ];
  };
in
{
  imports = servicesByPlatform.${platform} or [ ];
}
