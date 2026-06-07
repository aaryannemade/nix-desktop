{
  config,
  pkgs,
  import-tree,
  username,
  ...
}:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";

  # Create standard home directories on activation
  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
      extraConfig = {
        docker = "${config.home.homeDirectory}/docker";
        screenshots = "${config.home.homeDirectory}/Pictures/screenshots";
        screenrecordings = "${config.home.homeDirectory}/Videos/screenrecordings";
        trash = "${config.home.homeDirectory}/Trash";
      };
    };
  };

  imports = [
    (import-tree ./modules)
  ];

  services = {
    mpris-proxy = {
      enable = true;
    };
  };

  home.packages = with pkgs; [
    # Packages are now auto-imported from ./apps/ and ./modules/
    # Add any additional one-off packages here if needed
  ];
}
