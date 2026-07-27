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
  # host and selects the shared main or burner agenix-decrypted key. Clone or
  # set remotes with the alias, e.g. `git@gh:owner/repo.git`.
  #
  # identitiesOnly = true stops ssh from offering other keys in the agent first,
  # which otherwise causes "too many auth failures" against GitHub/GitLab.
  programs.ssh.settings = {
    gh = {
      hostname = "github.com";
      user = "git";
      identityFile = osConfig.age.secrets.git.path;
      identitiesOnly = true;
    };
    gh-burner = {
      hostname = "github.com";
      user = "git";
      identityFile = osConfig.age.secrets.git-burner.path;
      identitiesOnly = true;
    };
    glab = {
      hostname = "gitlab.com";
      user = "git";
      identityFile = osConfig.age.secrets.git.path;
      identitiesOnly = true;
    };
    glab-burner = {
      hostname = "gitlab.com";
      user = "git";
      identityFile = osConfig.age.secrets.git-burner.path;
      identitiesOnly = true;
    };
  };
}
