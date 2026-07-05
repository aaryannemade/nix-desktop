{ ... }:

{
  # Enable sound via PipeWire.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    raopOpenFirewall = true;
    wireplumber = {
      enable = true;
    };

    extraConfig.pipewire."10-airplay" = {
      "context.modules" = [
        {
          name = "libpipewire-module-raop-discover";

          # If AirPlay playback drops out, try setting "raop.latency.ms" here.
          # args."raop.latency.ms" = 500;
        }
      ];
    };
  };
}
