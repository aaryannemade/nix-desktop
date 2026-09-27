{
  pkgs,
  lib,
  cfg,
  image,
  secretPath,
  podman,
  graphicsDrivers,
}:

# `vpn-browser` CLI. Presets from my.vpnBrowser.profiles are baked in as JSON;
# the logic lives in ./vpn-browser.sh (kept as plain bash for readability).
let
  gluetunEnvFor =
    p:
    lib.filterAttrs (_: v: v != "") {
      SERVER_COUNTRIES = lib.concatStringsSep "," p.countries;
      SERVER_CITIES = lib.concatStringsSep "," p.cities;
      SERVER_HOSTNAMES = lib.concatStringsSep "," p.hostnames;
      SECURE_CORE_ONLY = lib.optionalString p.secureCore "on";
    }
    // p.extraGluetunEnv;

  presets = pkgs.writeText "vpn-browser-presets.json" (
    builtins.toJSON (
      lib.mapAttrs (_: p: {
        env = gluetunEnvFor p;
        tz = if p.timezone == null then "" else p.timezone;
      }) cfg.profiles
    )
  );

  # Store paths the /run/opengl-driver symlink farm resolves into.
  gpuClosure = pkgs.closureInfo { rootPaths = [ graphicsDrivers ]; };
in
pkgs.writeShellApplication {
  name = "vpn-browser";

  runtimeInputs = [
    podman
    pkgs.jq
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.findutils
    pkgs.libnotify
  ];

  text = ''
    IMAGE_STREAM=${image}
    IMAGE_REF=${lib.escapeShellArg "${image.imageName}:${image.imageTag}"}
    GLUETUN_IMAGE=${lib.escapeShellArg cfg.gluetunImage}
    SECRET_PATH=${lib.escapeShellArg secretPath}
    PRESETS=${presets}
    DL_SUBDIR=${lib.escapeShellArg cfg.downloadsDir}
    GPU_DEFAULT=${lib.escapeShellArg cfg.gpu}
    GPU_DRIVERS=${graphicsDrivers}
    GPU_CLOSURE=${gpuClosure}/store-paths

    ${builtins.readFile ./vpn-browser.sh}
  '';
}
