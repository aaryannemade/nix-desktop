# Optional: clone this repo into a user's home on first boot.
#
# Used by the generic WSL image so that after import a functional Git checkout
# lives at ~/nix-desktop and you can converge to the real host with `nrs`
# (nixos-rebuild switch --flake ~/nix-desktop#<host>).
#
# The service does not clobber an existing ~/nix-desktop. It waits for the
# network and retries if GitHub is temporarily unavailable.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.seedRepo;
in
{
  options.my.seedRepo = {
    enable = lib.mkEnableOption "cloning the config repo into a user's home";

    url = lib.mkOption {
      type = lib.types.str;
      description = "Public Git URL to clone.";
    };

    bundle = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Optional embedded Git bundle path used instead of the network.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "User that should own the seeded ~/nix-desktop.";
    };

    destination = lib.mkOption {
      type = lib.types.str;
      default = "/home/${cfg.user}/nix-desktop";
      defaultText = "/home/<user>/nix-desktop";
      description = "Absolute path to clone the repo into.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.seed-nix-desktop-repo = {
      description = "Clone the nix-desktop configuration repository";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = [
        pkgs.coreutils
        pkgs.git
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "15s";
      };

      script = ''
        if [ -L "${cfg.destination}" ] && [ ! -e "${cfg.destination}" ]; then
          rm -f "${cfg.destination}"
        fi

        if [ ! -e "${cfg.destination}" ]; then
          mkdir -p "$(dirname "${cfg.destination}")"
          rm -rf "${cfg.destination}.tmp"

          if [ -n "${cfg.bundle}" ] && [ -f "${cfg.bundle}" ]; then
            echo "[seed-repo] cloning embedded bundle to ${cfg.destination}"
            git clone "${cfg.bundle}" "${cfg.destination}.tmp"
            git -C "${cfg.destination}.tmp" remote set-url origin "${cfg.url}"
          else
            echo "[seed-repo] cloning ${cfg.url} to ${cfg.destination}"
            git clone "${cfg.url}" "${cfg.destination}.tmp"
          fi

          mv "${cfg.destination}.tmp" "${cfg.destination}"
        fi

        chown -R "${cfg.user}" "${cfg.destination}"
      '';
    };
  };
}
