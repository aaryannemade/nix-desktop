# Optional: seed a writable copy of this repo into a user's home on first boot.
#
# Used by the generic distributable images (the installer ISO's installed
# system and the generic WSL image) so that after boot/import the repo already
# lives at ~/nix-desktop and you can converge to the real host with `nrs`
# (nixos-rebuild switch --flake ~/nix-desktop#<host>).
#
# It copies from a read-only store path (self) exactly once: it will not clobber
# an existing ~/nix-desktop, so it is a no-op on machines that already have the
# repo checked out.
#
# NOTE: the baremetal ISO does NOT use this module. Its installer
# (hosts/installer/deploy.nix) copies the repo at install time into the target's
# /mnt so it can also drop the freshly generated hardware-configuration.nix into
# the host dir. That install-time copy has no access to `self` from within the
# standalone minimal config it writes, so activation-based seeding does not apply
# there. This module is for images with no install step (i.e. WSL).
{
  config,
  lib,
  ...
}:

let
  cfg = config.my.seedRepo;
in
{
  options.my.seedRepo = {
    enable = lib.mkEnableOption "seeding a writable repo copy into a user's home";

    source = lib.mkOption {
      type = lib.types.path;
      description = "Read-only store path to copy from (typically the flake `self`).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "User that should own the seeded ~/nix-desktop.";
    };

    destination = lib.mkOption {
      type = lib.types.str;
      default = "/home/${cfg.user}/nix-desktop";
      defaultText = "/home/<user>/nix-desktop";
      description = "Absolute path to seed the repo into.";
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.seed-nix-desktop-repo = {
      text = ''
        if [ ! -e "${cfg.destination}" ]; then
          echo "[seed-repo] seeding ${cfg.destination} from ${cfg.source}"
          mkdir -p "$(dirname "${cfg.destination}")"
          cp -r --no-preserve=mode,ownership "${cfg.source}" "${cfg.destination}"
          chown -R "${cfg.user}" "${cfg.destination}"
        fi
      '';
    };
  };
}
