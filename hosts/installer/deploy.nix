# The `nix-desktop-install` helper baked into the installer ISO.
#
# Flow (B-style, "install minimal, converge later"):
#   1. Generate hardware-config for the mounted target at /mnt.
#   2. Write a minimal, secret-free, bootable configuration.nix to /mnt.
#   3. nixos-install (prompts for the root password), then set the aaryan
#      password interactively inside the target.
#   4. Clone the embedded release bundle into the installed ~/nix-desktop.
#   5. Scaffold a new host when needed and place the generated hardware config
#      at hosts/<hostname>/ (existing host configuration is preserved).
#   6. Print the post-boot convergence steps (ssh host key, secrets, nrs).
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

    REPO_URL="https://github.com/aaryannemade/nix-desktop.git"
    REPO_BUNDLE="/etc/nix-desktop.bundle"
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

    if [[ ! "$hostname" =~ ^[a-z0-9][a-z0-9-]{0,62}$ ]]; then
      echo "error: hostname must contain only lowercase letters, numbers, and hyphens." >&2
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

    echo "[nix-desktop-install] Preparing release repository ..."
    dest="/mnt/home/$USER_NAME/nix-desktop"
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"

    if [ -f "$REPO_BUNDLE" ]; then
      git clone "$REPO_BUNDLE" "$dest"
      git -C "$dest" remote set-url origin "$REPO_URL"
    else
      echo "warning: image has no embedded bundle; cloning $REPO_URL" >&2
      git clone "$REPO_URL" "$dest"
    fi

    host_dir="$dest/hosts/$hostname"
    if [ ! -f "$host_dir/configuration.nix" ]; then
      echo "[nix-desktop-install] Scaffolding new host '$hostname' ..."
      mkdir -p "$host_dir"

      cat > "$host_dir/configuration.nix" <<EOF
    { hostname, ... }:

    {
      imports = [
        ../../configuration.nix
        ./hardware-configuration.nix
      ];

      time.timeZone = "Asia/Calcutta";

      programs.zsh.shellAliases.nrs =
        "sudo nixos-rebuild switch --flake ~/nix-desktop#$hostname";
    }
    EOF

      defaults="$dest/hosts/default.nix"
      defaults_new="$(mktemp)"
      inserted=false
      while IFS= read -r line || [ -n "$line" ]; do
        if [ "$inserted" = false ] && [[ "$line" == *"# Future hosts go here:"* ]]; then
          cat >> "$defaults_new" <<EOF
      "$hostname" = mkHost {
        hostname = "$hostname";
        username = "$USER_NAME";
        platform = "nixos";
        shownGpus = [
          "nvidia"
          "intel"
        ];
      };

    EOF
          inserted=true
        fi
        printf '%s\n' "$line" >> "$defaults_new"
      done < "$defaults"

      if [ "$inserted" = false ]; then
        echo "error: could not find the host insertion marker in $defaults" >&2
        rm -f "$defaults_new"
        exit 1
      fi
      mv "$defaults_new" "$defaults"
    fi

    # Place the freshly generated hardware-config into the host dir so it is
    # ready in the working tree. Existing host configuration remains untouched.
    mkdir -p "$host_dir"
    cp --no-preserve=mode,ownership \
      /mnt/etc/nixos/hardware-configuration.nix \
      "$host_dir/hardware-configuration.nix"

    chown -R "$USER_UID:$USER_GID" "$dest"

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

      environment.systemPackages = [ pkgs.git ];

      services.openssh.enable = true;

      users.users.$USER_NAME = {
        isNormalUser = true;
        uid = $USER_UID;
        extraGroups = [ "wheel" "networkmanager" ];
      };

      system.stateVersion = "$STATE_VERSION";
    }
    EOF

    echo "[nix-desktop-install] Installing (you will be prompted for the root password) ..."
    nixos-install --root /mnt

    echo "[nix-desktop-install] Set a password for user '$USER_NAME':"
    nixos-enter --root /mnt -c "passwd $USER_NAME"

    cat <<EOF

    [nix-desktop-install] Done. Minimal system installed.

    Next steps:
      1. Reboot into the new system.
      2. Inspect the SSH host key generated on first boot:
           cat /etc/ssh/ssh_host_ed25519_key.pub
         For an existing host, you may instead restore its previous key:
           sudo scp you@other:/path/ssh_host_ed25519_key /etc/ssh/
      3. On another authorized host, add the new public key to secrets/secrets.nix,
         rekey with that host's existing identity, commit, and push the changes.
      4. Pull those changes here and review the generated host files:
           git -C ~/nix-desktop pull --ff-only
           git -C ~/nix-desktop status
      5. Converge to the real host config only after its key can decrypt secrets:
           sudo nixos-rebuild switch --flake ~/nix-desktop#$hostname
         (your 'nrs' alias does this once the host is defined)

      Until then, the minimal installed system remains fully bootable and usable.

    EOF
  '';
}
