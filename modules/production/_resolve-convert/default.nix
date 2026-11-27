{
  pkgs,
  lib,
  outputDir,
}:

# `resolve-convert` CLI: re-encodes media into codecs the free DaVinci Resolve
# can decode on Linux. The logic lives in ./resolve-convert.sh (kept as plain
# bash for readability).
pkgs.writeShellApplication {
  name = "resolve-convert";

  runtimeInputs = [
    pkgs.ffmpeg-headless
    pkgs.jq
    pkgs.coreutils
    pkgs.findutils
  ];

  text = ''
    DEFAULT_OUT_DIR=${lib.escapeShellArg outputDir}

    ${builtins.readFile ./resolve-convert.sh}
  '';
}
