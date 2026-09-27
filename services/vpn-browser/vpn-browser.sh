# shellcheck shell=bash
# vpn-browser: LibreWolf in a rootless podman pod behind gluetun (ProtonVPN WG).
#
# Injected by launcher.nix before this file:
#   IMAGE_STREAM   streamLayeredImage script (prints image tarball to stdout)
#   IMAGE_REF      localhost/vpn-browser-librewolf:<nix-hash>
#   GLUETUN_IMAGE  pinned gluetun image
#   SECRET_PATH    agenix-decrypted WireGuard private key
#   PRESETS        JSON: { <name>: { env: {K: V}, tz: "..." } }
#   DL_SUBDIR      downloads root relative to $HOME
#   GPU_DEFAULT    auto|nvidia|dri|none (my.vpnBrowser.gpu)

readonly PREFIX="vpnb"
readonly CHOME="/home/vpnb"
readonly HEALTH_TIMEOUT=60

usage() {
  cat <<EOF
Usage:
  vpn-browser <preset> [options]           launch a preset (see --list)
  vpn-browser --country <C> [options]      ad-hoc location, no rebuild needed

Launch options:
  --country <name>     gluetun SERVER_COUNTRIES (repeatable)
  --city <name>        gluetun SERVER_CITIES (repeatable)
  --hostname <name>    gluetun SERVER_HOSTNAMES (repeatable)
  --secure-core        ProtonVPN Secure Core servers only
  --profile <name>     profile/volume name (default: preset or first location)
  --tz <zone>          timezone inside the browser (e.g. Asia/Tokyo)
  --persistence        keep the profile in volume vpnb-profile-<profile>
                       (default: ephemeral tmpfs profile, discarded on close)

Management:
  --list               presets and running pods
  --ip <profile>       VPN exit IP / location
  --logs <profile>     gluetun logs
  --shell <profile>    bash inside the running browser container
  --stop <profile>     stop a running pod
  --stop-all           stop every vpn-browser pod
  --forget <profile>   delete a profile's persistent volume
  -h, --help           this help

Environment:
  VPN_BROWSER_GPU=auto|nvidia|dri|none   GPU passthrough (default: $GPU_DEFAULT)
EOF
}

notify_err() {
  # Desktop-entry launches have no terminal; surface errors as notifications.
  if [[ ! -t 2 ]] && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    notify-send -u critical "vpn-browser" "$1" 2>/dev/null || true
  fi
}

die() {
  echo "vpn-browser: $*" >&2
  notify_err "$*"
  exit 1
}

log() { echo "vpn-browser: $*" >&2; }

pod_of() { echo "${PREFIX}-$1"; }
volume_of() { echo "${PREFIX}-profile-$1"; }

valid_profile() {
  [[ "$1" =~ ^[a-z0-9][a-z0-9_.-]*$ ]] || die "invalid profile name '$1' (use a-z 0-9 _ . -)"
}

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//; s/-*$//'
}

require_running() {
  podman pod exists "$(pod_of "$1")" || die "profile '$1' is not running"
}

# ── management commands ────────────────────────────────────────────────────

cmd_list() {
  echo "Presets:"
  jq -r 'to_entries[] | "  \(.key)\t\(.value.env | to_entries | map("\(.key)=\(.value)") | join(" "))"' "$PRESETS"
  echo
  echo "Running:"
  local pods
  pods="$(podman pod ps --filter "name=^${PREFIX}-" --format '  {{.Name}}\t{{.Status}}\t{{.Created}}')"
  if [[ -n "$pods" ]]; then echo "$pods"; else echo "  (none)"; fi
  echo
  echo "Profile volumes:"
  local vols
  vols="$(podman volume ls --filter "name=^${PREFIX}-profile-" --format '  {{.Name}}')"
  if [[ -n "$vols" ]]; then echo "$vols"; else echo "  (none)"; fi
}

cmd_ip() {
  local p="$1" c
  require_running "$p"
  c="$(pod_of "$p")-gluetun"
  # gluetun looks up its public IP a few seconds after the tunnel is healthy.
  local out i
  for ((i = 0; i < 15; i++)); do
    out="$(podman exec "$c" wget -qO- http://127.0.0.1:8000/v1/publicip/ip 2>/dev/null || true)"
    if [[ -n "$out" && "$out" != *'"public_ip":""'* ]]; then
      echo "$out"
      return
    fi
    sleep 1
  done
  podman logs "$c" 2>&1 | grep -i 'public ip address' | tail -n1 ||
    die "could not determine exit IP; check: vpn-browser --logs $p"
}

cmd_logs() {
  local p="$1"
  require_running "$p"
  podman logs --tail 200 "$(pod_of "$p")-gluetun"
}

cmd_shell() {
  local p="$1"
  require_running "$p"
  exec podman exec -it "$(pod_of "$p")-browser" /bin/bash
}

cmd_stop() {
  local p="$1"
  require_running "$p"
  podman pod rm -f -t 5 "$(pod_of "$p")" >/dev/null
  log "stopped '$p'"
}

cmd_stop_all() {
  local pods
  pods="$(podman pod ps -q --filter "name=^${PREFIX}-")"
  if [[ -z "$pods" ]]; then
    log "nothing running"
    return
  fi
  # shellcheck disable=SC2086
  podman pod rm -f -t 5 $pods >/dev/null
  log "stopped all"
}

cmd_forget() {
  local p="$1" v
  valid_profile "$p"
  podman pod exists "$(pod_of "$p")" && die "profile '$p' is running; stop it first"
  v="$(volume_of "$p")"
  podman volume exists "$v" || die "no volume for profile '$p'"
  podman volume rm "$v" >/dev/null
  log "deleted volume $v (downloads in ~/$DL_SUBDIR/$p are kept)"
}

# ── launch ─────────────────────────────────────────────────────────────────

ensure_images() {
  if ! podman image exists "$IMAGE_REF"; then
    log "loading browser image $IMAGE_REF (first run after rebuild)..."
    "$IMAGE_STREAM" | podman load >/dev/null
    # Drop stale builds of the browser image, keeping the current one.
    podman images --format '{{.Repository}}:{{.Tag}}' --filter "reference=${IMAGE_REF%%:*}" |
      grep -vFx "$IMAGE_REF" | xargs -r podman rmi >/dev/null 2>&1 || true
  fi
  if ! podman image exists "$GLUETUN_IMAGE"; then
    log "pulling $GLUETUN_IMAGE..."
    podman pull -q "$GLUETUN_IMAGE" >/dev/null
  fi
}

# Prints one podman argument per line.
gpu_args() {
  local mode="${VPN_BROWSER_GPU:-$GPU_DEFAULT}"
  if [[ "$mode" == auto ]]; then
    if [[ -e /dev/nvidiactl ]]; then
      mode=nvidia
    elif [[ -d /dev/dri ]]; then
      mode=dri
    else
      mode=none
    fi
  fi

  local d p
  case "$mode" in
    nvidia)
      for d in /dev/nvidiactl /dev/nvidia-modeset /dev/nvidia-uvm /dev/nvidia[0-9]*; do
        [[ -e "$d" ]] && echo "--device=$d"
      done
      ;;&
    nvidia | dri)
      [[ -d /dev/dri ]] && echo "--device=/dev/dri"
      # This generation's graphics drivers, plus every store path its symlinks
      # resolve into (paths also in the image are identical; binding is harmless).
      echo "--volume=$GPU_DRIVERS:/run/opengl-driver:ro"
      while IFS= read -r p; do
        echo "--volume=$p:$p:ro"
      done <"$GPU_CLOSURE"
      ;;
    none) ;;
    *) die "VPN_BROWSER_GPU must be auto|nvidia|dri|none" ;;
  esac
  return 0
}

cmd_launch() {
  local preset="" profile="" tz="" persistent=false secure_core=false
  local -a countries=() cities=() hostnames=()

  while (($#)); do
    case "$1" in
      --country) countries+=("${2:?--country needs a value}"); shift 2 ;;
      --city) cities+=("${2:?--city needs a value}"); shift 2 ;;
      --hostname) hostnames+=("${2:?--hostname needs a value}"); shift 2 ;;
      --secure-core) secure_core=true; shift ;;
      --profile) profile="${2:?--profile needs a value}"; shift 2 ;;
      --tz) tz="${2:?--tz needs a value}"; shift 2 ;;
      --persistence | --persistent) persistent=true; shift ;;
      -*) die "unknown option '$1' (see --help)" ;;
      *)
        [[ -z "$preset" ]] || die "only one preset allowed"
        preset="$1"
        shift
        ;;
    esac
  done

  # Resolve gluetun environment: preset first, flags appended (last wins).
  local -a genv=()
  if [[ -n "$preset" ]]; then
    jq -e --arg p "$preset" 'has($p)' "$PRESETS" >/dev/null ||
      die "unknown preset '$preset' (see --list)"
    mapfile -t genv < <(jq -r --arg p "$preset" '.[$p].env | to_entries[] | "\(.key)=\(.value)"' "$PRESETS")
    [[ -n "$tz" ]] || tz="$(jq -r --arg p "$preset" '.[$p].tz // ""' "$PRESETS")"
    [[ -n "$profile" ]] || profile="$preset"
  fi

  local IFS_OLD="$IFS"
  IFS=,
  ((${#countries[@]})) && genv+=("SERVER_COUNTRIES=${countries[*]}")
  ((${#cities[@]})) && genv+=("SERVER_CITIES=${cities[*]}")
  ((${#hostnames[@]})) && genv+=("SERVER_HOSTNAMES=${hostnames[*]}")
  IFS="$IFS_OLD"
  $secure_core && genv+=("SECURE_CORE_ONLY=on")

  if [[ -z "$profile" ]]; then
    local seed="${hostnames[0]:-${cities[0]:-${countries[0]:-}}}"
    [[ -n "$seed" ]] || die "give a preset or at least one of --country/--city/--hostname (see --help)"
    profile="$(slugify "$seed")"
  fi
  valid_profile "$profile"

  local pod gl br
  pod="$(pod_of "$profile")"
  gl="${pod}-gluetun"
  br="${pod}-browser"

  # Preflight.
  podman pod exists "$pod" && die "profile '$profile' is already running (vpn-browser --stop $profile)"
  [[ -r "$SECRET_PATH" ]] || die "cannot read $SECRET_PATH (agenix secret protonvpn-wg missing?)"
  [[ -s "$SECRET_PATH" ]] || die "$SECRET_PATH is empty (agenix placeholder: decryption failed on this host)"
  [[ -n "${WAYLAND_DISPLAY:-}" ]] || die "WAYLAND_DISPLAY is not set; run from a Wayland session"
  [[ -n "${XDG_RUNTIME_DIR:-}" ]] || die "XDG_RUNTIME_DIR is not set"
  local wl_sock="$WAYLAND_DISPLAY"
  [[ "$wl_sock" == /* ]] || wl_sock="$XDG_RUNTIME_DIR/$wl_sock"
  [[ -S "$wl_sock" ]] || die "Wayland socket $wl_sock not found"

  local dl_dir="$HOME/$DL_SUBDIR/$profile"
  mkdir -p "$dl_dir"

  ensure_images

  # From here on, always tear the pod down on exit (a --persistence volume survives).
  # shellcheck disable=SC2064
  trap "podman pod rm -f -t 3 '$pod' >/dev/null 2>&1 || true" EXIT
  trap 'exit 130' INT TERM

  log "creating pod $pod"
  podman pod create \
    --name "$pod" \
    --label "vpn-browser.profile=$profile" \
    --userns=keep-id \
    --dns=127.0.0.1 \
    --hostname=localhost \
    --shm-size=2g \
    >/dev/null

  local -a genv_args=()
  local kv
  for kv in "${genv[@]}"; do genv_args+=(-e "$kv"); done

  log "starting gluetun (${genv[*]:-any server})"
  podman run -d \
    --pod "$pod" \
    --name "$gl" \
    --user 0:0 \
    --cap-add=NET_ADMIN \
    --device=/dev/net/tun \
    -v "$(realpath "$SECRET_PATH"):/run/secrets/wireguard_private_key:ro" \
    -e VPN_SERVICE_PROVIDER=protonvpn \
    -e VPN_TYPE=wireguard \
    -e WIREGUARD_PRIVATE_KEY_SECRETFILE=/run/secrets/wireguard_private_key \
    -e HTTP_CONTROL_SERVER_ADDRESS=127.0.0.1:8000 \
    -e 'HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE={"auth":"none"}' \
    -e UPDATER_PERIOD=0 \
    -e "TZ=${tz:-UTC}" \
    "${genv_args[@]}" \
    --health-cmd="/gluetun-entrypoint healthcheck" \
    --health-interval=disable \
    "$GLUETUN_IMAGE" >/dev/null

  log "waiting for VPN tunnel (up to ${HEALTH_TIMEOUT}s)..."
  local i
  for ((i = 0; i < HEALTH_TIMEOUT; i++)); do
    if [[ "$(podman inspect -f '{{.State.Running}}' "$gl" 2>/dev/null)" != true ]]; then
      podman logs --tail 30 "$gl" >&2 || true
      die "gluetun exited during startup (logs above)"
    fi
    if podman healthcheck run "$gl" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
  if ((i >= HEALTH_TIMEOUT)); then
    podman logs --tail 30 "$gl" >&2 || true
    die "VPN did not become healthy in ${HEALTH_TIMEOUT}s (logs above)"
  fi
  log "tunnel up"

  local uid rt
  uid="$(id -u)"
  rt="/run/user/$uid"

  local -a bargs=(
    --pod "$pod"
    --name "$br"
    --rm
    --cap-drop=all
    # Firefox's own sandbox chroots its content processes; without this they
    # segfault in a loop. Scoped to the container's user namespace.
    --cap-add=SYS_CHROOT
    --security-opt=no-new-privileges
    --mount "type=tmpfs,destination=$rt,tmpfs-mode=0700,chown=true"
    -v "$wl_sock:$rt/wayland-0"
    -e WAYLAND_DISPLAY=wayland-0
    -e "XDG_RUNTIME_DIR=$rt"
    -e "HOME=$CHOME"
    -e "TZ=${tz:-UTC}"
    -v "$dl_dir:$CHOME/Downloads"
  )

  if [[ -S "$XDG_RUNTIME_DIR/pulse/native" ]]; then
    bargs+=(-v "$XDG_RUNTIME_DIR/pulse/native:$rt/pulse/native" -e "PULSE_SERVER=unix:$rt/pulse/native")
  else
    log "no PipeWire/Pulse socket found; audio disabled"
  fi

  if $persistent; then
    bargs+=(-v "$(volume_of "$profile"):$CHOME")
    log "persistent profile: kept in volume $(volume_of "$profile")"
  else
    bargs+=(--mount "type=tmpfs,destination=$CHOME,chown=true")
    log "ephemeral profile: discarded on close (use --persistence to keep it)"
  fi

  local -a gargs=()
  mapfile -t gargs < <(gpu_args)
  bargs+=("${gargs[@]}")

  log "launching LibreWolf ($profile)"
  # shellcheck disable=SC2016 # expanded inside the container, not here
  podman run "${bargs[@]}" \
    --entrypoint /bin/bash \
    "$IMAGE_REF" \
    -c 'mkdir -p "$HOME/profile" && exec librewolf --name "$1" --profile "$HOME/profile" --no-remote' \
    _ "vpn-browser-$profile"
}

# ── dispatch ───────────────────────────────────────────────────────────────

need_arg() { [[ -n "${1:-}" ]] || die "missing <profile> argument (see --help)"; }

case "${1:-}" in
  "" | -h | --help) usage ;;
  --list) cmd_list ;;
  --ip) need_arg "${2:-}"; cmd_ip "$2" ;;
  --logs) need_arg "${2:-}"; cmd_logs "$2" ;;
  --shell) need_arg "${2:-}"; cmd_shell "$2" ;;
  --stop) need_arg "${2:-}"; cmd_stop "$2" ;;
  --stop-all) cmd_stop_all ;;
  --forget) need_arg "${2:-}"; cmd_forget "$2" ;;
  *) cmd_launch "$@" ;;
esac
