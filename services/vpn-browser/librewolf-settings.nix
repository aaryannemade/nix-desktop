{ lib }:

# Container-only LibreWolf configuration, intentionally separate from the host
# browser (modules/browsers/_librewolf.nix). Baked into the image via
# `librewolf.override { extraPolicies; extraPrefs; }`, so it applies to every
# VPN profile. LibreWolf's own hardened defaults (librewolf.cfg) load first;
# these prefs are appended after and win.
let
  # `pref` sets a default the user can still change in about:config;
  # `lockPref` cannot be changed from inside the browser.
  prefs = {
    # Look & feel, matching the host browser.
    "ui.systemUsesDarkTheme" = 1;
    "widget.wayland.fractional-scale.enabled" = false;

    # Don't wipe on shutdown: ephemeral profiles vanish with the tmpfs anyway,
    # and `--persistence` profiles should keep cookies/history/sessions.
    "privacy.sanitize.sanitizeOnShutdown" = false;
    "privacy.clearOnShutdown.cookies" = false;
    "privacy.clearOnShutdown.history" = false;
    "privacy.clearOnShutdown.sessions" = false;
    "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
    "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = false;
    "network.cookie.lifetimePolicy" = 0;

    # Hardware acceleration (NVIDIA via CDI).
    "gfx.webrender.all" = true;
    "media.ffmpeg.vaapi.enabled" = true;
  };

  lockedPrefs = {
    # WebRTC: only ever expose the default route (= the VPN tunnel).
    "media.peerconnection.ice.default_address_only" = true;
    "media.peerconnection.ice.no_host" = true;

    # No geolocation; the exit location should be the only location signal.
    "geo.enabled" = false;

    # Image is immutable; updates come from the Nix rebuild.
    "app.update.auto" = false;

    # Never let the browser bypass gluetun's DNS with its own DoH resolver.
    "network.trr.mode" = 5;
  };

  render =
    fn: attrs:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (k: v: "${fn}(${builtins.toJSON k}, ${builtins.toJSON v});") attrs
    );
in
{
  extraPrefs = ''
    ${render "pref" prefs}
    ${render "lockPref" lockedPrefs}
  '';

  extraPolicies = {
    DisableAppUpdate = true;
    DisableTelemetry = true;
    DisableFirefoxStudies = true;
    DontCheckDefaultBrowser = true;
    OverrideFirstRunPage = "";
    OverridePostUpdatePage = "";

    # $HOME/Downloads is bind-mounted from ~/Downloads/vpn-browser/<profile>.
    DefaultDownloadDirectory = "\${home}/Downloads";
    PromptForDownloadLocation = false;

    ExtensionSettings = {
      # Proton Pass, installed from AMO (latest).
      "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
        installation_mode = "force_installed";
        private_browsing = true;
        default_area = "navbar";
      };
    };
  };
}
