{
  pkgs,
  shownGpus ? [ ],
  ...
}:

{
  home.packages = with pkgs; [
    iotop
    htop
  ];

  programs.btop = {
    enable = true;

    settings = {
      color_theme = "noctalia";
      update_ms = 400;
      shown_boxes = "cpu mem net proc";
      shown_gpus = if shownGpus != [ ] then builtins.concatStringsSep " " shownGpus else "";
    };
  };
}
