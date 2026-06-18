{ ... }:

{
  # Enable sound via PipeWire.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    wireplumber = {
      enable = true;
    };
  };
}
