{ pkgs, ... }:

{
  programs.librewolf = {
    enable = true;

    #Optional, but explicit
    package = pkgs.librewolf;

    # Global librewolf settings
    settings = {
      # Enable WebGL
      "webgl.diable" = false;

      # Keep Cookies and Browsing History
      "privacy.resistFingerprinting" = false;
      "privacy.clearOnShutdown.history" = false;
      "privacy.clearOnShutdown.cookies" = false;
      "network.cookie.lifetimePolicy" = 0;

      #Theme
      "ui.systemUsesDarkTheme" = 1;
    };

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        proton-pass
      ];
    };
  };
}
