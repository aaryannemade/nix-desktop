{
  pkgs,
  platform,
  shownGpus ? [ ],
  ...
}:

{
  home.packages = with pkgs; [
    htop
  ];

  programs.btop = {
    enable = true;

    settings = {
      color_theme = if (platform == "nixos") then "noctalia" else "tokyo-night";
      update_ms = 400;
      shown_boxes = "cpu mem net proc";
      shown_gpus = if shownGpus != [ ] then builtins.concatStringsSep " " shownGpus else "";
    };
  };
}
