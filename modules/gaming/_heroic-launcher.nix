{ config, lib, pkgs, ... }:

let
  # Stable path (survives rebuilds) to the wrapper from _gamescope.nix, which
  # runs the game in gamescope at the current output's native resolution.
  wrapperExe = "${config.home.profileDirectory}/bin/steam-gamescope-native";

  # Prepend the gamescope wrapper to a wrapperOptions list, dropping any
  # existing copy so it isn't duplicated on each rebuild. Other wrappers the
  # user added in Heroic (e.g. gamemoderun) are kept and run inside gamescope.
  jqAddWrapper = ''
    def addwrapper: [{ exe: $exe, args: "--" }] + [ (. // [])[] | select(.exe != $exe) ];
  '';
in
{
  home.packages = with pkgs; [
    heroic
  ];

  # Heroic owns and rewrites its JSON config, so we merge into it rather than
  # managing the files with home.file (which would make them read-only).
  #  - config.json defaultSettings: applies to games installed in the future.
  #  - GamesConfig/<id>.json: per-game settings for already-installed games.
  # Rebuild while Heroic is closed, or Heroic may overwrite these changes.
  home.activation.heroicGamescopeWrapper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    heroicDir="${config.xdg.configHome}/heroic"

    heroicMerge() {
      local file="$1" filter="$2" tmp
      tmp="$(mktemp)"
      if ${pkgs.jq}/bin/jq --arg exe "${wrapperExe}" '${jqAddWrapper}'"$filter" "$file" > "$tmp"; then
        if ! ${pkgs.diffutils}/bin/cmp -s "$tmp" "$file"; then
          run cp "$tmp" "$file"
        fi
      else
        warnEcho "heroic: failed to update $file, leaving it unchanged"
      fi
      rm -f "$tmp"
    }

    if [ -f "$heroicDir/config.json" ]; then
      heroicMerge "$heroicDir/config.json" \
        '.defaultSettings.wrapperOptions |= addwrapper'
    fi

    if [ -d "$heroicDir/GamesConfig" ]; then
      for gameConfig in "$heroicDir"/GamesConfig/*.json; do
        [ -f "$gameConfig" ] || continue
        heroicMerge "$gameConfig" \
          'with_entries(if (.value | type) == "object" then .value.wrapperOptions |= addwrapper else . end)'
      done
    fi
  '';
}
