{ osConfig, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
      # These hosts are reached by mDNS, so the alias has to map to an explicit
      # <host>.local hostname.
      #
      # Bare names used to resolve only because the router's dnsmasq answered
      # them out of its DHCP lease table. Clients now query AdGuard directly and
      # the router is no longer in the path, so "rei" is NXDOMAIN. Without a
      # hostname here ssh tries to resolve the literal alias and fails -- and
      # working around it with `ssh admin@rei.local` silently skips this block,
      # losing identityFile and falling back to password auth.
      nerv = {
        hostname = "nerv.local";
        user = "admin";
        identityFile = osConfig.age.secrets.nerv-centr.path;
        identitiesOnly = true;
        sendEnv = [
          "COLORTERM"
          "TERM_PROGRAM"
          "TERM_PROGRAM_VERSION"
        ];
      };
      rei = {
        hostname = "rei.local";
        user = "admin";
        identityFile = osConfig.age.secrets.nerv-centr.path;
        identitiesOnly = true;
      };
      misato = {
        hostname = "misato.local";
        user = "admin";
        identityFile = osConfig.age.secrets.nerv-centr.path;
        identitiesOnly = true;
      };
      eva = {
        hostname = "eva.local";
        user = "admin";
        identityFile = osConfig.age.secrets.nerv-centr.path;
        identitiesOnly = true;
        sendEnv = [
          "COLORTERM"
          "TERM_PROGRAM"
          "TERM_PROGRAM_VERSION"
        ];
      };
      pwnagotchi = {
        user = "pi";
        hostname = "pwnagotchi.local";
        identityFile = osConfig.age.secrets.pwnagotchi.path;
        identitiesOnly = true;
        sendEnv = [
          "COLORTERM"
          "TERM_PROGRAM"
          "TERM_PROGRAM_VERSION"
        ];
      };
    };
  };
}
