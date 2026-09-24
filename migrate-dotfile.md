# Migrating `$HOME` to the XDG Base Directory spec

Runbook for cleaning up `$HOME` on a host that has not been migrated yet
(`wraith`, `specter`, `banshee`, ...). Written to be executed by a coding agent
or by hand.

**The Nix side is already done and is shared by every host.** Nothing in this
document edits the config. `nixos-rebuild switch` alone gives you the exported
`XDG_*` variables and all per-application overrides. What is left is the
*imperative* part: relocating or deleting files that already exist in `$HOME`
from before the migration. Nix cannot do that for you, and it deliberately does
not try.

## What the config already provides

| File | Provides |
| --- | --- |
| `modules/shell/_xdg.nix` | `xdg.enable = true` (exports `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME`, `XDG_BIN_HOME`) plus `NPM_CONFIG_*`, `BUN_INSTALL`, `CARGO_HOME`, `GOPATH`, `CUDA_CACHE_PATH`, `XCOMPOSECACHE`, `PULSE_COOKIE`, `CLAUDE_CONFIG_DIR`, `WGETRC`, and `~/.config/wget/wgetrc` |
| `modules/shell/_zsh.nix` | `history.path` → `$XDG_STATE_HOME/zsh/history`, `dotDir` → `$XDG_CONFIG_HOME/zsh`, `nvidia-settings` alias |
| `modules/browsers/_librewolf.nix` | disables home-manager's stray `~/.mozilla` stub |
| `system/nixos/display.nix` | `ly.settings.session_log` → `.local/state/ly-session.log` (NixOS hosts only) |

## Step 1 — rebuild

```sh
sudo nixos-rebuild switch --flake ~/nix-desktop#<hostname>
```

## Step 2 — verify the variables, from a clean environment

`hm-session-vars.sh` guards itself with `__HM_SESS_VARS_SOURCED` and returns
early if that is already set. Any shell started *before* the rebuild has it
exported, so it will keep showing the old (empty) values and make a correct
migration look broken. Always unset it when verifying:

```sh
env -u __HM_SESS_VARS_SOURCED -u __HM_ZSH_SESS_VARS_SOURCED \
  zsh -l -c 'echo $XDG_STATE_HOME $GOPATH $CARGO_HOME $CLAUDE_CONFIG_DIR'
```

Expected:

```
/home/aaryan/.local/state /home/aaryan/.local/share/go /home/aaryan/.local/share/cargo /home/aaryan/.config/claude
```

A real login shell (log out and back in) is required before day-to-day use.

## Step 3 — migrate `$HOME`

Write this to `/tmp/xdg-migrate.sh`, read it, then run it. It is idempotent:
every path is skipped if absent, so it is safe on a host where only some of
these exist.

```sh
#!/usr/bin/env bash
set -euo pipefail

: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"

move() { # move SRC DEST, only when SRC exists and DEST does not
  local src=$1 dest=$2
  [[ -e $src ]] || { echo "skip (absent): $src"; return; }
  if [[ -e $dest ]]; then
    echo "SKIP (dest exists): $src -> $dest    <-- resolve by hand"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  mv -v "$src" "$dest"
}

nuke() { # regenerable caches; apps recreate them at the new path
  for p in "$@"; do
    if [[ ! -e $p ]]; then
      echo "skip (absent): $p"
      continue
    fi
    # Go marks its module cache read-only (dirs 0555), so a plain rm -rf dies
    # with EACCES on every file. Same trick `go clean -modcache` uses.
    chmod -R u+w "$p" 2>/dev/null || true
    if rm -rf --one-file-system "$p"; then
      echo "removed: $p"
    else
      echo "FAILED to remove: $p" >&2
    fi
  done
}

echo "== relocating real state =="
move "$HOME/.claude"             "$XDG_CONFIG_HOME/claude"
move "$HOME/.zsh_history"        "$XDG_STATE_HOME/zsh/history"
move "$HOME/.pulse-cookie"       "$XDG_CONFIG_HOME/pulse/cookie"
move "$HOME/.nvidia-settings-rc" "$XDG_CONFIG_HOME/nvidia/settings"

echo
echo "== deleting regenerable caches =="
nuke \
  "$HOME/.npm" \
  "$HOME/.cargo" \
  "$HOME/go" \
  "$HOME/.bun" \
  "$HOME/.nv" \
  "$HOME/.compose-cache" \
  "$HOME/.wget-hsts" \
  "$HOME/.vim"

echo
echo "== stray logs and junk =="
rm -fv "$HOME/ly-session.log" "$HOME"/steam-*.log
```

Run it in the background and log it; the Go cache alone can emit thousands of
lines:

```sh
nohup bash /tmp/xdg-migrate.sh > /tmp/xdg-migrate.log 2>&1 &
rg -in 'FAILED|SKIP \(dest' /tmp/xdg-migrate.log
```

### Resolving the two cases the script refuses to guess

- **`SKIP (dest exists)` for `.pulse-cookie`** — a pulse cookie is a random auth
  token and `PULSE_COOKIE` already points at the new path. Delete the `$HOME`
  copy: `rm ~/.pulse-cookie`.
- **`SKIP (dest exists)` for `.claude`** — do *not* blind-overwrite. It holds
  `projects/`, `history.jsonl` and `.credentials.json`. Merge by hand.

## Step 4 — verify

```sh
env -u __HM_SESS_VARS_SOURCED zsh -l -c 'nix run nixpkgs#xdg-ninja -- --skip-unsupported'
ls -d ~/.[^.]*
```

On a migrated NixOS host only these should remain, and every one is either a
correct XDG directory or blocked upstream:

```
.bash_history   .cache   .claude.json   .config   .gnupg   .librewolf
.local   .nix-defexpr   .nix-profile   .ollama   .pki   .ssh
.steam   .steampath   .steampid   .zshenv
```

### Known-unfixable, do not attempt

| Path | Reason |
| --- | --- |
| `~/.zshenv` | Required to bootstrap a non-default `ZDOTDIR`; home-manager writes it. Something *must* live in `$HOME`. |
| `~/.ssh` | Assumed by OpenSSH and most daemons. |
| `~/.claude.json` | anthropics/claude-code#1455 |
| `~/.steam`, `~/.steampath`, `~/.steampid` | ValveSoftware/steam-for-linux#1890 |
| `~/.librewolf`, `~/.mozilla` | bugzilla.mozilla.org#259356 |
| `~/.ollama` | ollama/ollama#228 |
| `~/.pki` | XDG-capable, but Chromium hardcodes `$HOME/.pki` and recreates it. |
| `~/.nix-defexpr`, `~/.nix-profile` | Already symlink into `.local/state`. Fixing the rest needs `use-xdg-base-directories`, deliberately not enabled. |
| `~/.gnupg` | `GNUPGHOME` deliberately not set: needs a manual keyring move and changes the gpg-agent/ssh socket paths. We use agenix instead. |
| `~/.bash_history` | Would require `programs.bash.enable = true`, handing home-manager your `.bashrc`. |

## Per-host notes

- **NixOS hosts (`phantom`, `wraith`)** — everything above applies. `ly` and
  Steam are present, so `ly-session.log` and `steam-*.log` are worth removing.
- **WSL hosts (`specter`, `banshee`)** — no `ly`, no Steam, no CUDA cache. The
  script skips all of them automatically; no edits needed.
- Host-specific secrets living loose in `$HOME` (SSH host keys, password files)
  are **out of scope**. Do not move or delete them without asking — relocating
  a host key can lock you out of a machine.

## Optional — reclaiming `~/.cache`

Nix GC only manages `/nix/store`. A flake devShell provides the *tool*, not the
tool's cache, so `uv`, `pnpm`, `go`, `gem` and friends still fill `~/.cache`
from PyPI/npm/proxy.golang.org. `~/.cache/nix` is Nix's own client-side cache
and `nix store gc` never touches it either.

```sh
du -sh ~/.cache/* | sort -rh | head -15
```

`~/.cache/uv` is usually the worst offender (PyTorch plus duplicated CUDA 11 and
CUDA 12 runtimes). **Check before deleting** — `uv` hardlinks cache files into
project `.venv` directories:

```sh
find ~/.cache/uv/archive-v0 -type f -links +1 -printf '%s\n' \
  | awk '{s+=$1} END {printf "still referenced by a venv: %.1f GiB\n", s/1073741824}'
find ~/.cache/uv/archive-v0 -type f -links 1 -printf '%s\n' \
  | awk '{s+=$1} END {printf "orphaned, safe to delete: %.1f GiB\n", s/1073741824}'
```

If the first number is 0, the whole cache is orphaned. Prefer `uv cache prune`
inside a devShell where `uv` is on `PATH`; otherwise `rm -rf ~/.cache/uv`.

Other safe targets: `~/.cache/nix/tarball-cache-v2` (flake inputs, re-fetched on
demand), `~/.cache/go-build` (or `go clean -cache`), and browser caches under
`~/.cache/net.imput.helium` / `~/.cache/librewolf`.
