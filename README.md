# Nixos Desktop Configuration

### To Do List

- [x] Install Ollama
- [x] Fix issue with nvidia dgpu battery management - no change to config,
      laptop batter was just shitty
- [x] Install Blender
- [x] Install Opencode and cluade auth plugin
- [x] download wallpapers
- [x] Install color themer
- [x] install media player (mpv)
- [x] Install OBS
- [x] Install Zed IDE (backup for neovim)
- [x] set up fzf
- [x] add avahi and mdns resolution
- [x] Set up wallpapers (awww)
- [x] Install Yazi terminal file browser
- [x] Move Quickshell config to window-managers directory instead of flake input
- [x] Convert from quickshell to Noctalia-shell
- [x] Add Caveman skill to Opencode
- [x] Remove awww daemon
- [x] figure out approach to hide API keys (used agenix)
- [x] Create new host for pc
- [x] Create optimize core modules for better management with nix-darwin(macos)
- [ ] add support for devenv for development
- [x] transfer bootloader from systemd to grub
- [x] Set up RGB controls for PC host
- [x] Set up fan controls for PC host
- [x] Figure out Stream Deck set up
- [x] Set up auto-sleep on all hosts
- [x] Fix opencode github flake input
- [x] Implement the binary cache rollout above

## Agent skills

[skills-hub](https://github.com/aaryannemade/skills) owns the pinned skill sources
and selection through agent-skills-nix. `modules/ai/_skills.nix` imports its
Home Manager module and installs the selected skills on all regular hosts:

- Shared skills: `$XDG_CONFIG_HOME/agents/skills` (normally
  `~/.config/agents/skills`). OpenCode explicitly loads this directory through
  `skills.paths`; it is not an automatic discovery location.

Change sources or selection in the hub repository, then update this consumer
and apply it:

```sh
nix flake update skills-hub
sudo nixos-rebuild switch --flake .#<hostname>
```

Quit and restart OpenCode after activation to load the updated skills.
