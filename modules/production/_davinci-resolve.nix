{
  config,
  lib,
  pkgs,
  ...
}:

# DaVinci Resolve (free). It can't decode H.264 / H.265 / AAC on Linux, so
# `resolve-convert` transcodes footage into DNxHR/ProRes + PCM first:
#
#   resolve-convert clip.mp4 ~/Downloads/footage   # -> ~/Videos/resolve
#   resolve-convert --help
let
  resolve-convert = import ./_resolve-convert {
    inherit pkgs lib;
    outputDir = "${config.xdg.userDirs.videos}/resolve";
  };
in
{
  my.unfreePackages = [ "davinci-resolve" ];

  home.packages = [
    pkgs.davinci-resolve
    resolve-convert
  ];
}
