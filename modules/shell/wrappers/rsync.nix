{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "rsync-progress";
      runtimeInputs = with pkgs; [
        gawk
        pv
        rsync
      ];
      text = ''
        rsync --info=progress2 --no-inc-recursive "$@" |
          awk '
            BEGIN { RS = "\\r|\\n"; last = 0 }

            match($0, /[0-9]+%/) {
              percent = substr($0, RSTART, RLENGTH - 1) + 0
              stats = $1 "  " $3 "  " $4

              while (last < percent) {
                print stats
                last++
              }
              fflush()
              next
            }

            NF { print > "/dev/stderr" }
          ' |
          pv --wait --line-mode --size 100 --interval 0.1 --name rsync \
            --format '%N %t %40p %e  %35L' --discard
      '';
    })
  ];
}
