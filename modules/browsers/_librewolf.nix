{ pkgs, ... }:

{
  programs.librewolf = {
    enable = true;

    # Optional, but explicit.
    package = pkgs.librewolf;

    # Browser-wide enterprise policies (https://mozilla.github.io/policy-templates/).
    policies = {
      ExtensionSettings = {
        # Proton Pass — installed directly from AMO, always latest version.
        "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
          installation_mode = "force_installed";
          private_browsing = true;
          # Pin the toolbar button to the navigation bar by default.
          default_area = "navbar";
        };
      };
    };

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      settings = {
        # Enable WebGL
        "webgl.disable" = false;

        "widget.wayland.fractional-scale.enabled" = false;

        # Keep Cookies and Browsing History
        "privacy.resistFingerprinting" = false;
        "network.cookie.lifetimePolicy" = 0;

        # Master switch for clear-on-shutdown (LibreWolf enables this by default)
        "privacy.sanitize.sanitizeOnShutdown" = false;
        "privacy.clearOnShutdown.cookies" = false;
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.cache" = false;
        "privacy.clearOnShutdown.offlineApps" = false;
        "privacy.clearOnShutdown.sessions" = false;

        # Firefox 128+ / newer LibreWolf use the *_v2 keys
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
        "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = false;
        "privacy.clearOnShutdown_v2.cache" = false;

        # Theme
        "ui.systemUsesDarkTheme" = 1;
      };
    };
  };
}
