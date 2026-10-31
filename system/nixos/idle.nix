{ lib, ... }:

# Per-host idle timeouts (seconds), read by the home-manager noctalia config
# via osConfig (modules/window-managers/_noctalia-shell.nix). Set them in a
# host's configuration.nix:
#   my.idleTimeouts = { lock = 300; screenOff = 330; suspend = 900; };
let
  timeout =
    default: description:
    lib.mkOption {
      type = lib.types.ints.positive;
      inherit default description;
    };
in
{
  options.my.idleTimeouts = {
    lock = timeout 300 "Seconds idle before the session locks.";
    screenOff = timeout 330 "Seconds idle before the monitors are powered off (sleep).";
    suspend = timeout 900 "Seconds idle before the system suspends.";
  };
}
