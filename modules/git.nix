{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    userName = "Aaryan";
    userEmail = "aaryan.nemade@pm.me";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      credential.helper = "!glab auth git-credential";
    };
  };
}

