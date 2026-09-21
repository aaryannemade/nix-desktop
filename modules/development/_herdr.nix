{
  pkgs,
  inputs,
  ...
}:

# herdr — terminal workspace manager / runtime for AI coding agents.
#
# Config lives at ~/.config/herdr/config.toml. We generate it from Nix so the
# whole thing is declarative.
#
# CAVEAT: because the file becomes a read-only symlink into the Nix store,
# herdr cannot write back to it. That means the in-app Settings UI, the
# first-run onboarding writeback, and `herdr config reset-keys` will fail to
# persist. Everything must be changed here instead. `onboarding = false` below
# skips the first-run flow so herdr never tries to write on startup.
#
# After editing: rebuild, then `herdr server reload-config` (or `reload config`
# from the global menu) to pick up changes without restarting panes.
# Full option list: https://herdr.dev/docs/config-reference/
let
  toml = pkgs.formats.toml { };

  herdrPkg = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # `herdr integration install opencode` is an imperative command that drops
  # files into ~/.config/opencode/. That fights with a declarative setup, so we
  # run the installer inside a build sandbox and capture what it emits. The
  # payload is embedded in the herdr binary, so this pins the integration to
  # the exact herdr version from flake.lock automatically.
  #
  # The installer refuses to run unless the opencode config dir already exists,
  # hence the mkdir. It only writes local files -- no network access needed.
  #
  # It emits five files, but `herdr integration status` only requires four;
  # cli.json is optional (verified by bisecting the install). Dropping any of
  # the other four downgrades the status to "needs repair".
  herdrOpencodeIntegration = pkgs.runCommand "herdr-opencode-integration" { } ''
    export HOME="$NIX_BUILD_TOP/home"
    mkdir -p "$HOME/.config/opencode"
    ${herdrPkg}/bin/herdr integration install opencode

    mkdir -p "$out"
    cd "$HOME/.config/opencode"
    cp --parents \
      plugins/herdr-agent-state.js \
      herdr-tui-session.js \
      tui.jsonc \
      herdr-opencode/tui.js \
      "$out/"
  '';

  # xdg.configFile.<name>.source wants a bare store path; Nix's path coercion
  # rejects a "${drv}/subpath" string ("not the right placeholder for this
  # derivation output"). So slice each file out into its own single-file
  # derivation. The bundle above is built once and shared by all four.
  integrationFile =
    name: subpath:
    pkgs.runCommand "herdr-opencode-${name}" { } ''
      cp "${herdrOpencodeIntegration}/${subpath}" "$out"
    '';
in
{
  home.packages = [ herdrPkg ];

  # herdr's half of the opencode integration. Lives here rather than in
  # modules/ai/_opencode.nix because herdr owns these files; _opencode.nix owns
  # opencode.json and tui.json and manages neither plugins/ nor any of the
  # paths below, so there is no home-manager collision.
  #
  # These land as read-only store symlinks, so `herdr integration install` can
  # no longer overwrite them -- despite the "managed by herdr" header in the
  # generated files. That is intended: they now track the flake input instead.
  #
  # CAVEAT: on opencode 1.18.4 only the plugins/ entry actually does anything.
  # opencode reads tui.json and ignores tui.jsonc (it accepts the .jsonc
  # extension for opencode.json only), so the three TUI files below are inert
  # for now. They are still installed because herdr reports "needs repair"
  # without them, and because they light up once opencode reads tui.jsonc --
  # which is also what `session.resume_agents_on_restore` below needs in order
  # to get session refs back from opencode.
  xdg.configFile = {
    # Reports agent state (thinking/idle/waiting) to herdr over a unix socket;
    # this is what drives the sidebar status indicators configured below.
    # opencode auto-loads every file in ~/.config/opencode/plugins/ at startup.
    "opencode/plugins/herdr-agent-state.js".source =
      integrationFile "agent-state" "plugins/herdr-agent-state.js";

    "opencode/herdr-tui-session.js".source = integrationFile "tui-session" "herdr-tui-session.js";
    "opencode/herdr-opencode/tui.js".source = integrationFile "tui-entrypoint" "herdr-opencode/tui.js";
    "opencode/tui.jsonc".source = integrationFile "tui-config" "tui.jsonc";
  };

  xdg.configFile."herdr/config.toml".source = toml.generate "herdr-config.toml" {
    # Skip first-run setup; herdr would otherwise try to write this key back.
    onboarding = false;

    server = {
      # Virtual terminal size used for layout when no client is attached.
      headless_cols = 160;
      headless_rows = 50;
    };

    terminal = {
      # Unset default_shell => herdr uses $SHELL (zsh, see modules/shell/_zsh.nix).
      shell_mode = "auto";
      new_cwd = "follow";
      kitty_graphics = true;
    };

    session = {
      # Resume supported agent conversations after a server restart.
      resume_agents_on_restore = true;
    };

    worktrees = {
      directory = "~/.config/.herdr/worktrees";
    };

    remote = {
      manage_ssh_config = true;
    };

    theme = {
      name = "catppuccin";
      auto_switch = false;
    };

    ui = {
      tab_bar_position = "top";
      pane_borders = "auto";
      # Distinguish agent states by shape as well as colour.
      status_indicators = "symbols";
      window_title = "{hostname}: {workspace}";

      tab_bar_right = [
        { type = "zoom"; }
        { type = "hostname"; }
        {
          type = "datetime";
          format = "%H:%M";
        }
      ];
      tab_bar_right_separator = " · ";

      toast = {
        # "herdr" = in-app toast. Use "terminal" if you want notifications to
        # survive over SSH, or "system" for the local OS notification daemon.
        delivery = "herdr";
        delay_seconds = 1;
        herdr = {
          position = "bottom-right";
        };
      };

      sidebar = {
        agents = {
          row_gap = 0;
          rows = [
            [
              "state_icon"
              "machine"
              "workspace"
              "tab"
            ]
            [ "agent" ]
          ];
        };
        spaces = {
          row_gap = 0;
          rows = [
            [
              "state_icon"
              "workspace"
            ]
            [
              "branch"
              "git_status"
            ]
          ];
        };
      };
    };

    keys = {
      prefix = "ctrl+b";

      goto = "prefix+g";
      # Keep tmux-style bindings while adding Herdr's recommended direct
      # chords. ctrl+alt is largely unused by terminals and pane programs.
      new_tab = [
        "prefix+c"
        "ctrl+alt+c"
      ];
      next_tab = [
        "prefix+n"
        "ctrl+alt+]"
      ];
      previous_tab = [
        "prefix+p"
        "ctrl+alt+["
      ];

      split_horizontal = [
        "prefix+minus"
        "ctrl+alt+shift+d"
      ];
      split_vertical = [
        "prefix+backslash"
        "ctrl+alt+d"
      ];
      zoom = [
        "prefix+z"
        "ctrl+alt+z"
      ];

      # vim-style pane focus
      focus_pane_left = [
        "prefix+h"
        "ctrl+alt+h"
      ];
      focus_pane_down = [
        "prefix+j"
        "ctrl+alt+j"
      ];
      focus_pane_up = [
        "prefix+k"
        "ctrl+alt+k"
      ];
      focus_pane_right = [
        "prefix+l"
        "ctrl+alt+l"
      ];

      # navigate-mode movement (plain keys are allowed here only)
      navigate_pane_left = "h";
      navigate_pane_down = "j";
      navigate_pane_up = "k";
      navigate_pane_right = "l";

      # indexed jumps
      switch_tab = "prefix+1..9";
      switch_workspace = "prefix+shift+1..9";
      focus_agent = "prefix+alt+1..9";

      # Custom command keybindings -> [[keys.command]]
      command = [
        {
          key = "prefix+t";
          type = "popup";
          command = "exec \"\${SHELL:-sh}\"";
          description = "scratch terminal";
          width = "80%";
          height = "80%";
        }
        {
          key = "prefix+alt+g";
          type = "popup";
          command = "${pkgs.lazygit}/bin/lazygit";
          description = "lazygit";
          width = "90%";
          height = "90%";
        }
      ];
    };
  };
}
