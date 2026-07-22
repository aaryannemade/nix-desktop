{ osConfig, ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      user.name = "Aaryan";
      user.email = "aaryan.nemade@pm.me";

      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
    };
  };

  # SSH host aliases for multi-account git auth. Each alias points at the real
  # host but selects a distinct agenix-decrypted private key. Clone/remote with
  # the alias, e.g. `git@github-main:owner/repo.git`.
  #
  # identitiesOnly = true stops ssh from offering other keys in the agent first,
  # which otherwise causes "too many auth failures" against GitHub/GitLab.
  programs.ssh = {
    enable = true;
    # Opt out of the deprecated implicit default block; keep the "*" defaults we
    # want explicitly. Avoids the enableDefaultConfig deprecation warning.
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
      gh= {
        hostname = "github.com";
        user = "git";
        identityFile = osConfig.age.secrets.github-main.path;
        identitiesOnly = true;
      };
      gh-burner = {
        hostname = "github.com";
        user = "git";
        identityFile = osConfig.age.secrets.github-burner.path;
        identitiesOnly = true;
      };
      glab = {
        hostname = "gitlab.com";
        user = "git";
        identityFile = osConfig.age.secrets.gitlab-main.path;
        identitiesOnly = true;
      };
      glab-burner = {
        hostname = "gitlab.com";
        user = "git";
        identityFile = osConfig.age.secrets.gitlab-burner.path;
        identitiesOnly = true;
      };
    };
  };
}
