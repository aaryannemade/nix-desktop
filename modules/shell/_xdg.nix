{
  config,
  ...
}:

let
  inherit (config.xdg)
    cacheHome
    configHome
    dataHome
    ;
in
{
  # Export XDG_CONFIG_HOME / XDG_DATA_HOME / XDG_STATE_HOME / XDG_CACHE_HOME.
  #
  # Home-manager already *computes* these paths even when `xdg.enable = false`
  # (that is what `xdg.configFile` writes against), but it only exports them as
  # environment variables when enabled. Without the exports, programs that do
  # honour the spec fall back to their own defaults and keep littering $HOME.
  #
  # `xdg.enable` writes the variables to both `home.sessionVariables` (picked up
  # by the shell via hm-session-vars.sh) and `systemd.user.sessionVariables`, so
  # graphical children of the systemd user session see them too.
  #
  # User directories (Documents, Pictures, ...) are a separate concern and stay
  # in home.nix under `xdg.userDirs`.
  xdg.enable = true;

  # Per-application overrides for programs that do not honour the base
  # directory spec on their own. Everything here was reported by `xdg-ninja`.
  #
  # Deliberately NOT set, for the record:
  #   GNUPGHOME  - requires migrating the keyring by hand and changes the
  #                gpg-agent/ssh socket paths; not worth it while agenix
  #                handles our secrets.
  #   HISTFILE   - owned by programs.zsh.history.path in ./_zsh.nix.
  #   Unfixable upstream: ~/.ssh, ~/.steam, ~/.steampid, ~/.mozilla,
  #   ~/.librewolf, ~/.ollama, ~/.pki, ~/.claude.json, ~/.nix-defexpr.
  home.sessionVariables = {
    # npm. USERCONFIG also moves ~/.npmrc. NPM_CONFIG_TMP is intentionally
    # omitted: npm >= 7 ignores it and warns about it on every invocation.
    NPM_CONFIG_USERCONFIG = "${configHome}/npm/npmrc";
    NPM_CONFIG_INIT_MODULE = "${configHome}/npm/config/npm-init.js";
    NPM_CONFIG_CACHE = "${cacheHome}/npm";

    # bun only relocates its install/cache tree, the rest is still hardcoded.
    # See https://github.com/oven-sh/bun/issues/1678.
    BUN_INSTALL = "${dataHome}/bun";

    # cargo. GOPATH/CARGO_HOME hold caches plus the `bin` output directory;
    # neither bin dir is on PATH here, so nothing else needs adjusting.
    CARGO_HOME = "${dataHome}/cargo";
    GOPATH = "${dataHome}/go";

    # CUDA JIT compile cache (~/.nv).
    CUDA_CACHE_PATH = "${cacheHome}/nv";

    # libX11 Compose(3) cache (~/.compose-cache).
    XCOMPOSECACHE = "${cacheHome}/X11/xcompose";

    # PulseAudio client auth cookie. pipewire-pulse uses the same libpulse
    # client code, so this applies to us as well.
    PULSE_COOKIE = "${configHome}/pulse/cookie";

    # Claude Code. ~/.claude.json is still hardcoded, see
    # https://github.com/anthropics/claude-code/issues/1455.
    CLAUDE_CONFIG_DIR = "${configHome}/claude";

    # wget reads its per-user startup file from $WGETRC instead of ~/.wgetrc.
    # Using the rc file rather than a shell alias means non-interactive callers
    # (scripts, Makefiles) get the relocated HSTS database too.
    WGETRC = "${configHome}/wget/wgetrc";
  };

  xdg.configFile = {
    "wget/wgetrc".text = ''
      hsts-file = ${dataHome}/wget-hsts
    '';

    # nvidia-settings is aliased to `--config=$XDG_CONFIG_HOME/nvidia/settings`
    # in ./_zsh.nix, but it will not create the parent directory itself.
    "nvidia/.keep".text = "";
  };
}
