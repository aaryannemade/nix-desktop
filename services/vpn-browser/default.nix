{
  config,
  lib,
  pkgs,
  username,
  ...
}:

# Containerized LibreWolf behind gluetun (ProtonVPN WireGuard), on demand.
#
#   vpn-browser de                     # preset from my.vpnBrowser.profiles
#   vpn-browser --country Japan        # ad-hoc location, no rebuild
#   vpn-browser --server DE#14         # exact ProtonVPN server (needs the
#                                      #   ProtonVPN CLI's server cache)
#   vpn-browser --servers DE           # list server names
#   vpn-browser --help
#
# Everything runs as rootless podman under ${username}: no systemd units, no
# long-running services. Each launch creates pod `vpnb-<profile>` (gluetun +
# browser sharing one netns = kill switch) and removes it when the window
# closes. Profiles are ephemeral (tmpfs) by default; `--persistence` keeps
# them in podman volume `vpnb-profile-<profile>`.
#
# Enabled by importing ../../services from a host (NixOS desktops only).
let
  cfg = config.my.vpnBrowser;

  # The exact /run/opengl-driver target of this generation (mesa + NVIDIA +
  # egl-wayland ...). The launcher bind-mounts its closure read-only so the
  # browser uses the host's own GPU userspace, always matching the kernel
  # driver. (Replaces NVIDIA CDI: crun crashes combining CDI devices with a
  # keep-id pod.)
  graphicsDrivers =
    config.systemd.tmpfiles.settings.graphics-driver."/run/opengl-driver"."L+".argument;

  image = import ./image.nix { inherit pkgs lib; };

  vpn-browser = import ./launcher.nix {
    inherit
      pkgs
      lib
      cfg
      image
      graphicsDrivers
      ;
    secretPath = config.age.secrets.protonvpn-wg.path;
    podman = config.virtualisation.podman.package;
  };

  desktopItems = lib.mapAttrsToList (
    name: _:
    pkgs.makeDesktopItem {
      name = "vpn-browser-${name}";
      desktopName = "LibreWolf VPN (${name})";
      genericName = "Web Browser (VPN: ${name})";
      exec = "${lib.getExe vpn-browser} ${name}";
      icon = "librewolf";
      categories = [
        "Network"
        "WebBrowser"
      ];
      startupWMClass = "vpn-browser-${name}";
    }
  ) (lib.filterAttrs (_: p: p.desktopEntry) cfg.profiles);
in
{
  imports = [ ./options.nix ];

  assertions = [
    {
      assertion = config.virtualisation.podman.enable;
      message = "services/vpn-browser requires virtualisation.podman.enable (system/nixos/virtualization.nix).";
    }
  ]
  ++ lib.mapAttrsToList (name: _: {
    assertion = builtins.match "[a-z0-9][a-z0-9_.-]*" name != null;
    message = "my.vpnBrowser.profiles.${name}: name must match [a-z0-9][a-z0-9_.-]*";
  }) cfg.profiles;

  # ProtonVPN WireGuard private key (just the base64 key, not a full .conf).
  # Declared here, not in system/shared/secrets.nix, so only hosts importing
  # this service decrypt it.
  age.secrets.protonvpn-wg = {
    file = ../../secrets/protonvpn-wg.age;
    owner = username;
    mode = "0400";
  };

  # Rootless containers cannot autoload kernel modules. gluetun uses
  # userspace wireguard-go on /dev/net/tun when kernel WG is unavailable.
  boot.kernelModules = [
    "tun"
    "wireguard"
  ];

  # PRIME-offload laptops (phantom) composite on the iGPU: stay on /dev/dri so
  # the dGPU can sleep. Desktops (wraith) auto-detect NVIDIA.
  my.vpnBrowser.gpu = lib.mkDefault (
    if config.hardware.nvidia.prime.offload.enable then "dri" else "auto"
  );

  environment.systemPackages = [ vpn-browser ] ++ desktopItems;

  programs.zsh.shellAliases.vb = "vpn-browser";
}
