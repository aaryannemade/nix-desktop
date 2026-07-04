{ ... }:

{
  homebrew = {
    enable = true;

    casks = [
      "ghostty"

      # NOTE: no-quarantine has been deprecated by homebrew, working in current
      # version but might be deleted, careful during updating
      {
        name = "librewolf";
        args.no_quarantine = true;
      }

      "obs"
      "zed"
    ];
  };
}
