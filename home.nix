{
  config,
  lib,
  pkgs,
  import-tree,
  username,
  platform,
  homeDirectory,
  ...
}:

{
  imports = [
    (import-tree ./modules)
  ];

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "25.05";

  # Create standard home directories on activation.
  xdg = lib.mkIf (platform != "darwin") {
    userDirs = {
      enable = true;
      setSessionVariables = false;
      createDirectories = true;
      extraConfig = {
        screenshots = "${config.home.homeDirectory}/Pictures/screenshots";
        screenrecordings = "${config.home.homeDirectory}/Videos/screenrecordings";
        trash = "${config.home.homeDirectory}/Trash";
      };
    };
  };
}
