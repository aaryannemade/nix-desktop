{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "nix-desktop-install-help";
  runtimeInputs = [ pkgs.coreutils ];
  text = ''
    cat <<'EOF'
    NixOS installation quick reference

    WARNING: Confirm the target disk with lsblk. Replace /dev/vda if your
    target uses another name; formatting destroys data on those partitions.

    1. Inspect disks and partitions:
       lsblk

    2. Partition the target disk:
       cfdisk /dev/vda

       Suggested layout:
         /dev/vda1   2G    EFI System
         /dev/vda2   4G    Linux swap
         /dev/vda3   rest  Linux filesystem (/)

    3. Format the partitions:
       mkfs.ext4 -L nixos /dev/vda3
       mkswap -L swap /dev/vda2
       mkfs.fat -F 32 -n boot /dev/vda1

    4. Mount and enable swap:
       mount /dev/vda3 /mnt
       mount --mkdir /dev/vda1 /mnt/boot
       swapon /dev/vda2

    5. Install the minimal system:
       nix-desktop-install <hostname>
    EOF
  '';
}
