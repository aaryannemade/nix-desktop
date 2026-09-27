{ lib, ... }:

# Option surface for the containerized LibreWolf + gluetun launcher.
# Importing ../vpn-browser enables the service; there is no `enable` switch.
# Hosts may override/extend `my.vpnBrowser.profiles` to add their own presets.
let
  inherit (lib) mkOption types;

  profileModule =
    { name, ... }:
    {
      options = {
        countries = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "Germany" ];
          description = "gluetun SERVER_COUNTRIES filter.";
        };

        cities = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "Frankfurt" ];
          description = "gluetun SERVER_CITIES filter.";
        };

        hostnames = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "gluetun SERVER_HOSTNAMES filter (pin exact servers).";
        };

        secureCore = mkOption {
          type = types.bool;
          default = false;
          description = "Only use ProtonVPN Secure Core servers (SECURE_CORE_ONLY).";
        };

        timezone = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "Europe/Berlin";
          description = "TZ inside the browser container, to match the exit location.";
        };

        desktopEntry = mkOption {
          type = types.bool;
          default = true;
          description = "Generate a `LibreWolf VPN (${name})` desktop entry.";
        };

        extraGluetunEnv = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Extra environment variables passed verbatim to gluetun.";
        };
      };
    };
in
{
  options.my.vpnBrowser = {
    gluetunImage = mkOption {
      type = types.str;
      default = "docker.io/qmcgaw/gluetun:v3.41.3";
      description = "Pinned gluetun image. Bump deliberately.";
    };

    gpu = mkOption {
      type = types.enum [
        "auto"
        "nvidia"
        "dri"
        "none"
      ];
      default = "auto";
      description = ''
        Default GPU passthrough (overridable per launch with VPN_BROWSER_GPU).
        Both GPU modes bind-mount the host's /run/opengl-driver closure (mesa,
        NVIDIA, egl-wayland) read-only; glvnd picks the vendor that matches
        the compositor's GPU.
        auto: nvidia if /dev/nvidiactl exists, else dri.
        nvidia: /dev/dri + /dev/nvidia* (needed when the compositor runs on NVIDIA).
        dri: /dev/dri only (iGPU / AMD / Intel; keeps a PRIME dGPU asleep).
        none: software rendering.
      '';
    };

    downloadsDir = mkOption {
      type = types.str;
      default = "Downloads/vpn-browser";
      description = "Host downloads root, relative to $HOME. Each profile gets a subdirectory.";
    };

    profiles = mkOption {
      type = types.attrsOf (types.submodule profileModule);
      default = {
        de = {
          countries = [ "Germany" ];
          timezone = "Europe/Berlin";
        };
        us = {
          countries = [ "United States" ];
          timezone = "America/New_York";
        };
      };
      description = "Named VPN browser presets, launched with `vpn-browser <name>`.";
    };
  };
}
