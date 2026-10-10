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
#   TZ_TABLE       tzdata zone1970.tab (server location -> timezone)

readonly PREFIX="vpnb"
readonly CHOME="/home/vpnb"
readonly HEALTH_TIMEOUT=60

# --server: ProtonVPN server names (DE#14) are resolved through the server
# list cached by the official ProtonVPN CLI, which knows every logical server.
# gluetun's bundled list keeps only one name per machine, so the tunnel is
# pinned with gluetun's `custom` provider instead (Proton WG: fixed port and
# client address; the one private key works for every server).
SERVERLIST="${PROTON_SERVERLIST:-${XDG_CACHE_HOME:-$HOME/.cache}/Proton/VPN/serverlist.json}"
readonly PROTON_WG_PORT=51820
readonly PROTON_WG_ADDRESS="10.2.0.2/32"
readonly US=$'\x1f' # field separator for jq -> read (non-whitespace keeps empty fields)

usage() {
  cat <<EOF
Usage:
  vpn-browser <preset> [options]           launch a preset (see --list)
  vpn-browser --country <C> [options]      ad-hoc location, no rebuild needed
  vpn-browser --server <NAME> [options]    exact ProtonVPN server, e.g. DE#14

Launch options:
  --server <name>      exact ProtonVPN server (DE#14, CH-DE#2, de-14, ...);
                       resolved via the ProtonVPN CLI's server cache. Not
                       combinable with a preset or the location filters below.
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
  --servers [filter]   ProtonVPN server names; filter by country code (DE)
                       or city (Berlin)
  --ip <profile>       VPN exit IP / location
  --logs <profile>     gluetun logs
  --shell <profile>    bash inside the running browser container
  --stop <profile>     stop a running pod
  --stop-all           stop every vpn-browser pod
  --forget <profile>   delete a profile's persistent volume
  -h, --help           this help

Environment:
  VPN_BROWSER_GPU=auto|nvidia|dri|none   GPU passthrough (default: $GPU_DEFAULT)
  PROTON_SERVERLIST=<path>               server cache (default: $SERVERLIST)
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

# ── ProtonVPN server names ─────────────────────────────────────────────────

serverlist_expired() {
  jq -e '(.ExpirationTime // 0) < now' "$SERVERLIST" >/dev/null
}

# Makes sure the ProtonVPN CLI's server cache exists, refreshing it through the
# CLI when expired. A stale cache is still usable (names rarely change).
ensure_serverlist() {
  if [[ ! -r "$SERVERLIST" ]]; then
    die "no ProtonVPN server cache at $SERVERLIST; run 'protonvpn signin' and 'protonvpn countries list' (or set PROTON_SERVERLIST)"
  fi
  serverlist_expired || return 0

  if command -v protonvpn >/dev/null; then
    log "ProtonVPN server cache expired; refreshing via protonvpn CLI..."
    # Any server-list command refreshes the cache when expired; it exits 0
    # even when the refresh fails, so re-check the expiry afterwards.
    timeout 60 protonvpn countries list >/dev/null 2>&1 || true
  fi
  if serverlist_expired; then
    log "warning: using stale server cache (last updated $(jq -r '.LastModifiedTime // "?"' "$SERVERLIST")); is 'protonvpn info' signed in?"
  fi
}

# Resolves a server name to one of its online machines. Sets SRV_* globals.
# Matching: exact (case-insensitive), then ignoring punctuation (de-14 = DE#14).
resolve_server() {
  local query="$1" res
  ensure_serverlist

  # shellcheck disable=SC2016 # jq program
  res="$(jq -r --arg q "$query" --argjson seed "$RANDOM" --arg us "$US" '
    def norm: ascii_upcase | gsub("[^A-Z0-9]"; "");
    .LogicalServers as $all
    | .MaxTier as $maxtier
    | [.LogicalServers[] | select((.Name | ascii_upcase) == ($q | ascii_upcase))] as $exact
    | (if ($exact | length) > 0 then $exact
       else [.LogicalServers[] | select((.Name | norm) == ($q | norm))] end) as $m
    | if ($m | length) == 0 then "none"
      elif ($m | length) > 1 then "ambiguous\($us)\($m | map(.Name) | join(" "))"
      else $m[0] as $l
        | [$l.Servers[] | select(.Status == 1 and .X25519PublicKey != null)] as $up
        | if $l.Status != 1 or ($up | length) == 0 then "down\($us)\($l.Name)"
          else $up[$seed % ($up | length)] as $s
            | [$all[] | select(any(.Servers[]?; .EntryIP == $s.EntryIP)) | .Name]
              | sort_by(capture("#(?<n>[0-9]+)").n // "0" | tonumber) as $siblings
            | ["ok", $l.Name, $l.ExitCountry, $l.City, $l.Location.Lat, $l.Location.Long,
               $s.Domain, $s.EntryIP, $s.X25519PublicKey, $l.Tier, $maxtier, ($up | length),
               ($siblings | length), ($siblings | first), ($siblings | last)]
            | map(. // "" | tostring) | join($us)
          end
      end
  ' "$SERVERLIST")" || die "failed to read $SERVERLIST"

  local status rest
  IFS="$US" read -r status rest <<<"$res"
  case "$status" in
    ok) ;;
    ambiguous) die "server '$query' is ambiguous: $rest" ;;
    down) die "server $rest is offline / in maintenance right now; pick another (vpn-browser --servers)" ;;
    *)
      local prefix="${query%%#*}" near=""
      if [[ "$prefix" != "$query" ]]; then
        # shellcheck disable=SC2016 # jq program
        near="$(jq -r --arg p "${prefix^^}#" '
          [.LogicalServers[] | select(.Status == 1 and (.Name | startswith($p))) | .Name]
          | sort_by(capture("#(?<n>[0-9]+)").n // "0" | tonumber) | .[:12] | join(" ")
        ' "$SERVERLIST")"
      fi
      die "unknown ProtonVPN server '$query'${near:+ (e.g. $near)}; see vpn-browser --servers"
      ;;
  esac

  IFS="$US" read -r _ SRV_NAME SRV_COUNTRY SRV_CITY SRV_LAT SRV_LON SRV_DOMAIN \
    SRV_IP SRV_PUBKEY SRV_TIER SRV_MAXTIER SRV_MACHINES \
    SRV_SIBLINGS SRV_SIB_FIRST SRV_SIB_LAST <<<"$res"
  [[ -n "$SRV_IP" && -n "$SRV_PUBKEY" ]] || die "server $SRV_NAME has no WireGuard endpoint in the cache"
  if [[ -n "$SRV_MAXTIER" ]] && ((SRV_TIER > SRV_MAXTIER)); then
    log "warning: $SRV_NAME is tier $SRV_TIER but your plan is tier $SRV_MAXTIER; the handshake will likely fail"
  fi
}

# Timezone for a server: nearest zone1970.tab entry whose primary country
# matches, then any listed country, then nearest overall.
tz_for() {
  local cc="${1^^}" lat="${2:-0}" lon="${3:-0}"
  case "$cc" in
    UK) cc=GB ;; # Proton's code for the United Kingdom
    XK) cc=RS ;; # Kosovo is not in tzdata; same zone as Belgrade
  esac
  awk -F'\t' -v cc="$cc" -v lat="$lat" -v lon="$lon" '
    function dms(s, degdigits,   sign, v) {
      sign = substr(s, 1, 1) == "-" ? -1 : 1
      v = substr(s, 2)
      return sign * (substr(v, 1, degdigits) + substr(v, degdigits + 1, 2) / 60 \
        + (length(v) > degdigits + 2 ? substr(v, degdigits + 3, 2) / 3600 : 0))
    }
    /^#/ { next }
    {
      n = split($1, ccs, ",")
      rank = 2
      if (ccs[1] == cc) rank = 0
      else for (i = 2; i <= n; i++) if (ccs[i] == cc) rank = 1
      match($2, /^[+-][0-9]+/)
      la = dms(substr($2, 1, RLENGTH), 2)
      lo = dms(substr($2, RLENGTH + 1), 3)
      dx = (lo - lon) * cos((la + lat) / 2 * 3.14159265 / 180)
      dy = la - lat
      d = dx * dx + dy * dy
      if (!found || rank < brank || (rank == brank && d < bd)) {
        found = 1; best = $3; brank = rank; bd = d
      }
    }
    END { if (found) print best }
  ' "$TZ_TABLE"
}

cmd_servers() {
  local filter="${1:-}"
  ensure_serverlist
  # shellcheck disable=SC2016 # jq program
  jq -r --arg f "$filter" '
    def bit($b): ((. / $b | floor) % 2) == 1;
    def feats: [ (if bit(1) then "secure-core" else empty end),
                 (if bit(2) then "tor" else empty end),
                 (if bit(4) then "p2p" else empty end),
                 (if bit(8) then "stream" else empty end) ] | join(",");
    ($f | ascii_upcase | if . == "GB" then "UK" else . end) as $cc
    | ["NAME", "COUNTRY", "CITY", "LOAD", "FEATURES", "TIER", "STATUS", "HOSTNAME"],
      ( [.LogicalServers[]
         | select($f == "" or .ExitCountry == $cc or ((.City // "") | ascii_downcase) == ($f | ascii_downcase))]
        | sort_by(.ExitCountry, (.Name | split("#")[0]), (.Name | capture("#(?<n>[0-9]+)").n // "0" | tonumber))
        | .[]
        | [ .Name,
            (if .EntryCountry != .ExitCountry then "\(.EntryCountry)->\(.ExitCountry)" else .ExitCountry end),
            (.City // "-"),
            "\(.Load // "?")%",
            (.Features | feats | if . == "" then "-" else . end),
            (if .Tier == 0 then "free" else "plus" end),
            (if .Status == 1 then "online" else "maint" end),
            (.Domain // "-") ] )
    | @tsv
  ' "$SERVERLIST" | column -t -s $'\t'
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
  local preset="" profile="" tz="" persistent=false secure_core=false server=""
  local -a countries=() cities=() hostnames=()

  while (($#)); do
    case "$1" in
      --server)
        [[ -z "$server" ]] || die "only one --server allowed"
        server="${2:?--server needs a value}"
        shift 2
        ;;
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
  local provider=protonvpn
  local -a genv=()
  if [[ -n "$server" ]]; then
    if [[ -n "$preset" ]] || ((${#countries[@]} + ${#cities[@]} + ${#hostnames[@]})) || $secure_core; then
      die "--server pins one exact server; drop the preset / --country / --city / --hostname / --secure-core"
    fi
    resolve_server "$server"
    local machines=""
    ((SRV_MACHINES > 1)) && machines=" (random pick of $SRV_MACHINES machines)"
    log "server $SRV_NAME (${SRV_CITY:-?}, $SRV_COUNTRY) -> $SRV_DOMAIN $SRV_IP$machines"
    # Names sharing a machine differ only by a label the official app sends to
    # Proton's local agent; plain WireGuard (gluetun) can't select it.
    ((SRV_SIBLINGS > 1)) &&
      log "note: this machine also serves $SRV_SIB_FIRST..$SRV_SIB_LAST ($SRV_SIBLINGS names); they are equivalent here, and Proton picks the exit IP"
    provider=custom
    genv=(
      "WIREGUARD_ENDPOINT_IP=$SRV_IP"
      "WIREGUARD_ENDPOINT_PORT=$PROTON_WG_PORT"
      "WIREGUARD_PUBLIC_KEY=$SRV_PUBKEY"
      "WIREGUARD_ADDRESSES=$PROTON_WG_ADDRESS"
    )
    [[ -n "$tz" ]] || tz="$(tz_for "$SRV_COUNTRY" "$SRV_LAT" "$SRV_LON")"
    [[ -n "$profile" ]] || profile="$(slugify "$SRV_NAME")"
  elif [[ -n "$preset" ]]; then
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
    [[ -n "$seed" ]] || die "give a preset, --server, or at least one of --country/--city/--hostname (see --help)"
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

  log "starting gluetun ($provider: ${genv[*]:-any server})"
  podman run -d \
    --pod "$pod" \
    --name "$gl" \
    --user 0:0 \
    --cap-add=NET_ADMIN \
    --device=/dev/net/tun \
    -v "$(realpath "$SECRET_PATH"):/run/secrets/wireguard_private_key:ro" \
    -e "VPN_SERVICE_PROVIDER=$provider" \
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
  --servers) cmd_servers "${2:-}" ;;
  --ip) need_arg "${2:-}"; cmd_ip "$2" ;;
  --logs) need_arg "${2:-}"; cmd_logs "$2" ;;
  --shell) need_arg "${2:-}"; cmd_shell "$2" ;;
  --stop) need_arg "${2:-}"; cmd_stop "$2" ;;
  --stop-all) cmd_stop_all ;;
  --forget) need_arg "${2:-}"; cmd_forget "$2" ;;
  *) cmd_launch "$@" ;;
esac
