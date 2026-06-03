{ pkgs, ... }:

{
  programs.btop = {
    enable = true;
    package = pkgs.btop.override { cudaSupport = true; };

    settings = {
      color_theme = "tokyo-night";
      update_ms = 400;
      shown_boxes = "cpu mem net proc";
      shown_gpus = "nvidia intel";
    };
  };
}
