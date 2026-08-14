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
      nerv = {
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
        user = "aaryan";
        identityFile = osConfig.age.secrets.nerv-centr.path;
        identitiesOnly = true;
        sendEnv = [
          "COLORTERM"
          "TERM_PROGRAM"
          "TERM_PROGRAM_VERSION"
        ];
      };
      misato = {
        user = "admin";
        identityFile = osConfig.age.secrets.nerv-centr.path;
        identitiesOnly = true;
        sendEnv = [
          "COLORTERM"
          "TERM_PROGRAM"
          "TERM_PROGRAM_VERSION"
        ];
      };
      eva = {
        user = "admin";
        identityFile = osConfig.age.secrets.nerv-centr.path;
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
