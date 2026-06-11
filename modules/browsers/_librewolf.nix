{ pkgs, ... }:

{
  programs.librewolf = {
    enable = true;

    # Optional, but explicit.
    package = pkgs.librewolf;

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
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.cookies" = false;
        "network.cookie.lifetimePolicy" = 0;

        # Theme
        "ui.systemUsesDarkTheme" = 1;
      };

      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        proton-pass
      ];
    };
  };
}
