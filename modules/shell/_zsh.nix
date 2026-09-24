{
  config,
  pkgs,
  inputs,
  ...
}:

let
  # nixpkgs' oh-my-zsh snapshot is too old to contain the `herdr` plugin (see
  # the `ohmyzsh` input in flake.nix). Override only the source: nixpkgs keeps
  # doing the Nix-specific patching we want, namely rewriting ZSH to the store
  # path and unfunction-ing the self-updater.
  ohMyZsh = pkgs.oh-my-zsh.overrideAttrs (_old: {
    version = inputs.ohmyzsh.shortRev or "unstable";
    src = inputs.ohmyzsh;
  });
in
{
  imports = [
    ./wrappers/rsync.nix
  ];

  home.packages = with pkgs; [
    bat
    tree
    pv
    rsync
  ];

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Keep the history out of $HOME. Home-manager emits the `mkdir -p` for the
    # parent directory in .zshrc, so nothing has to pre-create it.
    #
    # Note that ~/.zshenv cannot be eliminated: it is the stub home-manager
    # writes to export ZDOTDIR and source $ZDOTDIR/.zshenv. Something has to
    # live in $HOME to bootstrap a non-default ZDOTDIR.
    history.path = "${config.xdg.stateHome}/zsh/history";

    oh-my-zsh = {
      enable = true;
      package = ohMyZsh;
      plugins = [
        "git"
        "npm"
        "node"
        "zoxide"
        "web-search"
        "systemd"
        "sudo"
        "shrink-path"
        "podman"
        "fzf"
        "herdr"
      ];
      # External theme, see https://github.com/ohmyzsh/ohmyzsh/wiki/External-themes
      theme = "spaceship";
      custom = "${pkgs.spaceship-prompt}/share/zsh/themes";
    };

    shellAliases = {
      cat = "bat";
      cd = "z";
      c = "clear";
      cp = "rsync-progress -ah";
      slow-cp = "rsync-progress -ah --bwlimit=5M";
      ll = "ls -la";
      btw = "echo I use nixos now, btw";
      # nvidia-settings has no environment variable for its rc file, only this
      # flag. The directory is pre-created in ./_xdg.nix.
      nvidia-settings = "nvidia-settings --config=${config.xdg.configHome}/nvidia/settings";
      vpn-connect = "protonvpn connect --country DE";
      vpn-disconnect = "protonvpn disconnect";
      c-activate = "claude -p --model haiku \"Output exactly this text and nothing else: 'Claude Auth Valid'\"";
    };

    initContent = ''
      # The herdr oh-my-zsh plugin defines `hrdrup='herdr update'`, which tries
      # to download and self-install over the read-only /nix/store path. herdr
      # is pinned by the `herdr` flake input, so updates happen via
      # `nix flake update herdr` instead. Guarded because the plugin bails out
      # early (defining no aliases) when herdr isn't on PATH.
      if (( $+aliases[hrdrup] )); then
        unalias hrdrup
      fi

      function __zoxide_fzf() {
        local dir
        dir=$(zoxide query -l | fzf --preview 'ls -la --color=always -- {}' --height 40% --reverse)
        if [[ -n "$dir" ]]; then
          builtin cd -- "$dir"
          zle reset-prompt
        fi
      }

      zle -N __zoxide_fzf
      bindkey '^g' __zoxide_fzf
    '';
  };
}
