{ ... }:

{
  fileSystems."/mnt/archive" = {
    device = "/dev/disk/by-uuid/66D8024FD8021DC5";
    fsType = "ntfs3";
    options = [
      "rw"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "uid=1000"
      "gid=100"
      "umask=022"
      "windows_names"
    ];
  };
}
