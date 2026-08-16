{ hostname, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    proton-vpn-cli
  ];

  networking.networkmanager.enable = true;

  # ---------------------------------------------------------------------------
  # Raspberry Pi USB gadget mode (Internet Connection Sharing)
  #
  # Problem: Raspberry Pi OS (rpi-usb-gadget) boots the gadget link in "SHARED"
  # mode by default: the Pi runs a DHCP server + NAT on 10.12.194.1/28 and hands
  # the *host* a lease that includes a default route. NetworkManager on this
  # machine happily accepts it, so plugging in a Pi hijacks the default route and
  # the desktop loses internet.
  #
  # Fix: claim the gadget interface with a profile that uses ipv4.method=shared.
  # A shared connection never installs a default route or upstream DNS, so the
  # host keeps its own uplink, and NetworkManager instead runs dnsmasq (DHCP+DNS)
  # and nftables masquerading for the Pi. NM's first shared connection always
  # lands on 10.42.0.1/24, which is exactly the gateway the Pi's ICS watcher
  # probes for, so the Pi auto-flips itself into CLIENT mode and gets internet.
  #
  # Matching is by driver, not interface name, so it works regardless of whether
  # udev names the device usb0 or enp0s20f0u3. cdc_ether/cdc_subset are what a Pi
  # g_ether gadget presents to a Linux host; real USB NIC dongles (r8152, asix,
  # ax88179) and phone tethering (rndis_host, cdc_ncm) are deliberately excluded
  # so they can still be used as an uplink.
  # ---------------------------------------------------------------------------
  networking.networkmanager.ensureProfiles.profiles = {
    usb-gadget-shared = {
      connection = {
        id = "usb-gadget-shared";
        type = "ethernet";
        autoconnect = "true";
        autoconnect-priority = "100";
        # 3 = "all": one profile may be active on several devices at once, so
        # more than one Pi can be plugged in simultaneously.
        multi-connect = "3";
      };
      match = {
        driver = "cdc_ether;cdc_subset;";
      };
      ipv4 = {
        method = "shared";
      };
      ipv6 = {
        method = "disabled";
      };
    };
  };

  # NetworkManager's shared mode installs its own nftables table for NAT and
  # forwarding, and flips net.ipv4.ip_forward on for as long as the connection is
  # up, but it does not open the host firewall for its dnsmasq. Podman/netavark
  # leaves the FORWARD policy at ACCEPT, so nothing else is needed here. (Docker
  # would set FORWARD to DROP, which silently kills the NAT - if it ever comes
  # back, this needs explicit FORWARD accepts for 10.42.0.0/16.)
  networking.firewall.extraCommands = ''
    # DHCP from gadget clients. NM's dnsmasq only binds to the shared interface,
    # so this is not reachable on any other link.
    iptables -w -I nixos-fw 1 -p udp --sport 68 --dport 67 -j nixos-fw-accept

    # DNS for clients inside the range NM hands out for shared connections.
    iptables -w -I nixos-fw 1 -s 10.42.0.0/16 -p udp --dport 53 -j nixos-fw-accept
    iptables -w -I nixos-fw 1 -s 10.42.0.0/16 -p tcp --dport 53 -j nixos-fw-accept
  '';

  services = {
    avahi = {
      enable = true;
      ipv6 = false;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
  };
}
