# The `nix-desktop-install` helper baked into the installer ISO.
#
# Flow (B-style, "install minimal, converge later"):
#   1. Generate hardware-config for the mounted target at /mnt.
#   2. Write a minimal, secret-free, bootable configuration.nix to /mnt.
#   3. nixos-install (prompts for the root password), then set the aaryan
#      password interactively inside the target.
#   4. Drop a writable copy of this repo into the installed ~/nix-desktop and
#      place the generated hardware-config at hosts/<hostname>/.
#   5. Print the post-boot convergence steps (ssh host key, secrets, nrs).
#
# Assumes the target drives are already mounted under /mnt (ESP at /mnt/boot).
# It does NOT partition disks and does NOT bake any secrets.
{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "nix-desktop-install";
  runtimeInputs = with pkgs; [
    coreutils
    util-linux # mountpoint
    nixos-install-tools # nixos-generate-config, nixos-install, nixos-enter
    git
    openssh # ssh-keygen (for the printed guidance)
  ];
  text = ''
    set -euo pipefail

    # Read-only copy of the repo baked into the ISO (see configuration.nix).
    REPO_SRC="/etc/nix-desktop"
    USER_NAME="aaryan"
    USER_UID="1000"
    USER_GID="100"
    STATE_VERSION="25.05"

    hostname="''${1:-}"

    if [ "$(id -u)" -ne 0 ]; then
      echo "error: must run as root (use sudo)." >&2
      exit 1
    fi

    if [ -z "$hostname" ]; then
      echo "usage: nix-desktop-install <hostname>" >&2
      echo "  (mount the target root at /mnt and its ESP at /mnt/boot first)" >&2
      exit 1
    fi

    if ! mountpoint -q /mnt; then
      echo "error: /mnt is not a mountpoint." >&2
      echo "Partition and mount the target first, e.g.:" >&2
      echo "  mount /dev/disk/by-label/nixos /mnt" >&2
      echo "  mkdir -p /mnt/boot && mount /dev/disk/by-label/ESP /mnt/boot" >&2
      exit 1
    fi

    echo "[nix-desktop-install] Generating hardware configuration for /mnt ..."
    nixos-generate-config --root /mnt

    echo "[nix-desktop-install] Writing minimal bootable configuration.nix ..."
    cat > /mnt/etc/nixos/configuration.nix <<EOF
    # Minimal bootable config written by nix-desktop-install.
    # Boots without any secrets so first activation always succeeds. Converge to
    # the real host after reboot with: nixos-rebuild switch --flake ~/nix-desktop#$hostname
    { pkgs, ... }:

    {
      imports = [ ./hardware-configuration.nix ];

      boot.loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };
        grub = {
          enable = true;
          efiSupport = true;
          device = "nodev";
        };
      };

      networking.hostName = "$hostname";
      networking.networkmanager.enable = true;

      nix.settings.experimental-features = [ "nix-command" "flakes" ];

      services.openssh.enable = true;

      programs.zsh.enable = true;
      users.defaultUserShell = pkgs.zsh;

      users.users.$USER_NAME = {
        isNormalUser = true;
        uid = $USER_UID;
        extraGroups = [ "wheel" "networkmanager" ];
        shell = pkgs.zsh;
      };

      system.stateVersion = "$STATE_VERSION";
    }
    EOF

    echo "[nix-desktop-install] Installing (you will be prompted for the root password) ..."
    nixos-install --root /mnt

    echo "[nix-desktop-install] Set a password for user '$USER_NAME':"
    nixos-enter --root /mnt -c "passwd $USER_NAME"

    echo "[nix-desktop-install] Placing repo copy in /home/$USER_NAME/nix-desktop ..."
    dest="/mnt/home/$USER_NAME/nix-desktop"
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    cp -r --no-preserve=mode,ownership "$REPO_SRC" "$dest"

    # Place the freshly generated hardware-config into the host dir so it is
    # ready in the working tree (create the dir for a brand-new host).
    host_dir="$dest/hosts/$hostname"
    mkdir -p "$host_dir"
    cp --no-preserve=mode,ownership \
      /mnt/etc/nixos/hardware-configuration.nix \
      "$host_dir/hardware-configuration.nix"

    chown -R "$USER_UID:$USER_GID" "$dest"

    cat <<EOF

    [nix-desktop-install] Done. Minimal system installed.

    Next steps:
      1. Reboot into the new system.
      2. Set the SSH host key so agenix can decrypt secrets, either:
           sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
         or copy an existing key in:
           sudo scp you@other:/path/ssh_host_ed25519_key /etc/ssh/
      3. Add this host's public key (cat /etc/ssh/ssh_host_ed25519_key.pub) to
         allHosts in ~/nix-desktop/secrets/secrets.nix, then rekey:
           nix run github:ryantm/agenix -- -r -i /etc/ssh/ssh_host_ed25519_key
      4. If '$hostname' is a NEW host, add this block to ~/nix-desktop/hosts/default.nix:

           $hostname = mkHost {
             hostname = "$hostname";
             username = "$USER_NAME";
             platform = "nixos";
             shownGpus = [ "nvidia" "intel" ];
           };

      5. Commit the generated hardware config:
           git -C ~/nix-desktop add hosts/$hostname/hardware-configuration.nix
      6. Converge to the real host config:
           sudo nixos-rebuild switch --flake ~/nix-desktop#$hostname
         (your 'nrs' alias does this once the host is defined)

    EOF
  '';
}
