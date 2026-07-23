{ lib, platform, ... }:

{
  programs.ghostty = {
    enable = true;

    package = lib.mkIf (platform != "nixos") null;

    # When package is null (non-nixos: WSL/darwin) the systemd user service has
    # nothing to launch and the module asserts. Disable it off-nixos.
    systemd.enable = lib.mkIf (platform != "nixos") false;

    enableZshIntegration = true;
    settings = {
      window-theme = "dark";
      theme = if (platform == "nixos") then "noctalia" else "catppuccin-macchiato";
      background-opacity = 0.8;
      background-opacity-cells = true;
      shell-integration-features = "ssh-env,ssh-terminfo";
    };
  };
}
