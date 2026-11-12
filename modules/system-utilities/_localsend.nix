{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:

let
  theme = "dark";
  color = "oled";

  # LocalSend rewrites this file itself; a read-only home.file would break it.
  # Merge only our settings, preserving certificates, favorites and history.
  configureLocalSend = pkgs.writeShellScript "configure-localsend" ''
    set -euo pipefail
    file="$1"
    alias="$2"
    dir="$(${pkgs.coreutils}/bin/dirname "$file")"
    umask 077
    ${pkgs.coreutils}/bin/mkdir -p "$dir"
    tmp="$(${pkgs.coreutils}/bin/mktemp "$dir/.shared_preferences.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT

    input=/dev/null
    if [ -f "$file" ]; then
      input="$file"
    fi

    ${pkgs.jq}/bin/jq -s --arg alias "$alias" \
      --arg theme ${lib.escapeShellArg theme} \
      --arg color ${lib.escapeShellArg color} '
      (if length == 0 then {}
       elif length == 1 and (.[0] | type) == "object" then .[0]
       else error("LocalSend preferences must be a JSON object")
       end)
      + {
        "flutter.ls_alias": $alias,
        "flutter.ls_theme": $theme,
        "flutter.ls_color": $color
      }
    ' "$input" > "$tmp"

    if [ ! -f "$file" ] || ! ${pkgs.diffutils}/bin/cmp -s "$tmp" "$file"; then
      ${pkgs.coreutils}/bin/mv "$tmp" "$file"
    fi
  '';
in
{
  home.packages = [ pkgs.localsend ];

  # Close LocalSend during activation so its cached preferences cannot undo
  # this merge. `run` also honors Home Manager's dry-run mode.
  home.activation.localsendSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${configureLocalSend} \
      ${lib.escapeShellArg "${config.xdg.dataHome}/org.localsend.localsend_app/shared_preferences.json"} \
      ${lib.escapeShellArg hostname}
  '';
}
