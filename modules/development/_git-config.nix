{ pkgs, ... }:

{
  home.packages = with pkgs; [
    glab
  ];

  programs.git = {
    enable = true;

    lfs.enable = true;

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
