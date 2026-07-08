# Nixos Desktop Configuration

### To Do List
- [x] Install Ollama
- [x] Fix issue with nvidia dgpu battery management - no change to config, laptop batter was just shitty
- [x] Install Blender
- [x] Install Opencode and cluade auth plugin
- [x] download wallpapers
- [x] Install color themer
- [x] install media player (mpv)
- [x] Install OBS
- [ ] Figure out Stream Deck set up
- [x] Install Zed IDE (backup for neovim)
- [x] set up fzf
- [x] add avahi and mdns resolution
- [x] Set up wallpapers (awww)
- [x] Install Yazi terminal file browser
- [x] Move Quickshell config to window-managers directory instead of flake input
- [x] Convert from quickshell to Noctalia-shell
- [x] Add Caveman skill to Opencode
- [x] Remove awww daemon
- [x] figure out approach to hide API keys (used agenix)
- [ ] Create new host for pc
- [x] Create optimize core modules for better management with nix-darwin(macos)
- [ ] add support for devenv for development
- [x] transfer bootloader from systemd to grub

## WRAITH HOST SETUP

Manual install of the `wraith` desktop from the minimal ISO, driven from
`phantom`. The key idea: the minimal system generates the SSH host key on
first boot, which is then registered with agenix *before* the flake config
is deployed, so secrets decrypt on the first `nixos-rebuild switch`.

### Phase 1 — Install (wraith, minimal ISO)

Disk layout (dual-boot, Windows stays): 1.8 TB disk with an existing
200 MB ESP, ~1.3 TB Windows NTFS (C:), and ~525 GB unallocated at the
end. NixOS goes into the unallocated space as a single LVM partition.
The existing Windows ESP is reused — mounted at `/boot`, **never
formatted**. 200 MB is plenty: GRUB (`copyKernels = false`) keeps
kernels in `/nix/store` on the LVM root (GRUB reads LVM natively), so
only the GRUB EFI binary + config land on the ESP. `useOSProber = true`
in bootloader.nix adds the Windows entry to the boot menu.

- [ ] In Windows first: disable Fast Startup, and suspend/disable
      BitLocker on C: (a new bootloader can trigger the recovery
      prompt).
- [ ] Boot the minimal ISO and identify the disk/partition numbers:
      `lsblk -o NAME,SIZE,FSTYPE,PARTTYPENAME`. Windows also has a
      hidden 16 MB MSR partition that Disk Management doesn't show, so
      numbering may differ. Commands below assume `/dev/nvme0n1` with
      `p1` = 200 MB ESP and the new partition created as `p5` — adjust
      to what lsblk actually shows.
- [ ] Create the LVM partition in the unallocated space with cfdisk:
      `sudo cfdisk /dev/nvme0n1`, then:
      - select the **Free space** entry (the ~525 GB one) -> `New` ->
        accept the full size
      - with the new partition selected: `Type` -> **Linux LVM**
      - `Write` (type `yes` to confirm) -> `Quit`
      - do NOT touch the existing ESP/NTFS/MSR partitions
- [ ] Create the volume group and logical volumes (16G swap, rest
      root). Check the new partition's number first with `lsblk`
      (assumed `p5` below — adjust):

      ```sh
      sudo pvcreate /dev/nvme0n1p5
      sudo vgcreate vg0 /dev/nvme0n1p5
      sudo lvcreate -L 16G -n swap vg0
      sudo lvcreate -l 100%FREE -n root vg0

      sudo mkfs.ext4 -L nixos /dev/vg0/root
      sudo mkswap -L swap /dev/vg0/swap
      ```

- [ ] Mount everything under `/mnt` (swapon before generating the
      config so swap is picked up):

      ```sh
      sudo mount /dev/vg0/root /mnt
      sudo mkdir -p /mnt/boot
      sudo mount /dev/nvme0n1p1 /mnt/boot   # existing Windows ESP — do NOT format
      sudo swapon /dev/vg0/swap
      ```

- [ ] Run `nixos-generate-config --root /mnt`.
- [ ] Replace `/mnt/etc/nixos/configuration.nix` with
      `hosts/wraith/installer-configuration.nix` from this repo.
- [ ] Sanity check the generated `hardware-configuration.nix`: LVM
      fileSystems present, `boot.kernelModules` matches the CPU
      (`kvm-amd`/`kvm-intel`).
- [ ] `nixos-install`, set the root password when prompted, reboot.
- [ ] Log in, set the user password: `passwd aaryan` (as root). This
      password survives the flake switch (`mutableUsers` is on).
- [ ] Note wraith's IP (`ip a`).

### Phase 2 — Wire into the repo (phantom)

- [ ] Copy artifacts from wraith:
      `scp aaryan@<wraith-ip>:/etc/nixos/hardware-configuration.nix hosts/wraith/`
      `scp aaryan@<wraith-ip>:/etc/ssh/ssh_host_ed25519_key.pub /tmp/wraith.pub`
- [ ] Uncomment the `./hardware-configuration.nix` import in
      `hosts/wraith/configuration.nix`.
- [ ] Add the pubkey to `secrets/secrets.nix`: new `wraith = "ssh-ed25519
      ..."` binding and append `wraith` to `allHosts`.
- [ ] Rekey: `cd secrets && agenix -r`.
- [ ] `git commit` everything. Critical: flakes only see git-tracked
      files, and the rsync below carries `.git` along.

### Phase 3 — Deploy (wraith)

- [ ] From phantom: `rsync -a ~/nix-desktop/ aaryan@<wraith-ip>:nix-desktop/`
- [ ] On wraith: `sudo nixos-rebuild switch --flake ~/nix-desktop#wraith`
- [ ] Verify: `hostname` is `wraith`, `/run/agenix/deepseek` exists,
      `nrs` alias works for future rebuilds.
- [ ] Later, at leisure: set up the GitLab SSH key so the repo can push.
