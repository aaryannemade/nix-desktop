{ ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };

    # /etc/bluetooth/input.conf
    input = {
      General = {
        # Use the kernel's HIDP transport instead of BlueZ's userspace UHID.
        # With UHID, bluetoothd destroys the HID device whenever an output
        # report (lightbar/LEDs/rumble) write hits a transient EAGAIN, so a
        # DualSense stays "connected" but stops sending input ~1s after
        # connecting. Kernel HIDP queues output reports instead.
        UserspaceHID = false;
      };
    };
  };
}
