{ pkgs, ... }:

let
  steamGamescopeNative = pkgs.writeShellApplication {
    name = "steam-gamescope-native";
    runtimeInputs = with pkgs; [
      gamescope
      wlr-randr
      gawk
      gnused
    ];
    text = ''
      set -euo pipefail

      if [ "''${1:-}" = "--" ]; then
        shift
      fi

      if [ "$#" -eq 0 ]; then
        printf 'usage: steam-gamescope-native -- <command> [args...]\n' >&2
        exit 1
      fi

      mode_line="$(${pkgs.wlr-randr}/bin/wlr-randr | ${pkgs.gawk}/bin/awk '
        /^[^[:space:]]/ { enabled = 0 }
        /^[[:space:]]+Enabled: yes$/ { enabled = 1 }
        enabled && /current/ { print; exit }
      ')"

      width="''${GAMESCOPE_WIDTH:-$(${pkgs.gnused}/bin/sed -E 's/^[[:space:]]*([0-9]+)x([0-9]+).*/\1/' <<< "$mode_line")}"
      height="''${GAMESCOPE_HEIGHT:-$(${pkgs.gnused}/bin/sed -E 's/^[[:space:]]*([0-9]+)x([0-9]+).*/\2/' <<< "$mode_line")}"

      if [ -z "$width" ] || [ -z "$height" ] || [ "$width" = "$mode_line" ] || [ "$height" = "$mode_line" ]; then
        printf 'steam-gamescope-native: could not detect the current output mode from wlr-randr\n' >&2
        exit 1
      fi

      export WLR_NO_HARDWARE_CURSORS=1

      exec ${pkgs.gamescope}/bin/gamescope \
        --fullscreen \
        -W "$width" \
        -H "$height" \
        -w "$width" \
        -h "$height" \
        -- "$@"
    '';
  };
in
{
  home.packages = with pkgs; [
    gamescope
    steamGamescopeNative
  ];
}
