{ pkgs, ... }:

{
  programs = {
    mpv = {
      enable = true;
      package = pkgs.mpv.override {
        scripts = with pkgs.mpvScripts; [
          uosc
          sponsorblock
        ];
      };

      config = {
        profile = "high-quality";
        ytdl-format = "bestvideo+bestaudio";
        demuxer-max-bytes = "4000000KiB";
      };
    };
  };

}
