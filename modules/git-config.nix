{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user.name = "Aaryan";
      user.email = "aaryan.nemade@pm.me";

      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      credential.helper = "!glab auth git-credential";
    };
  };
}

