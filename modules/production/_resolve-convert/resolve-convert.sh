# shellcheck shell=bash
# resolve-convert: transcode media into codecs the free (non-Studio) DaVinci
# Resolve can decode on Linux. It has no H.264 / H.265 (HEVC) / AAC support, so
# video becomes DNxHR or ProRes in .mov and audio becomes PCM.
#
# Injected by default.nix before this file:
#   DEFAULT_OUT_DIR  default output directory (overridable: RESOLVE_CONVERT_DIR / -o)

readonly VIDEO_EXTS="mp4 m4v mov mkv webm avi mts m2ts ts 3gp flv wmv mxf mpg mpeg"
readonly AUDIO_EXTS="mp3 m4a aac wav flac ogg oga opus wma aif aiff"

# Streams Resolve (free, Linux) already decodes are copied instead of re-encoded.
readonly VIDEO_OK="dnxhd prores cfhd mjpeg"

usage() {
  cat <<EOF
Usage: resolve-convert [options] <file|dir>...

Converts video to DNxHR/ProRes (.mov) and audio to PCM, so the free version
of DaVinci Resolve can import it. Directories are searched recursively and
their layout is kept under the output directory.

Options:
  -o, --output <dir>   output directory (default: $DEFAULT_OUT_DIR)
  -p, --preset <name>  video codec preset (default: auto)
                         auto        dnxhr-hq for 8-bit, dnxhr-hqx for 10-bit+
                         dnxhr-lb    proxy-grade, smallest
                         dnxhr-sq    good for 8-bit delivery
                         dnxhr-hq    high quality 8-bit
                         dnxhr-hqx   high quality 10-bit (HDR / log footage)
                         dnxhr-444   10-bit 4:4:4
                         prores-lt, prores, prores-hq, prores-4444
      --fps <rate>     force a constant frame rate (e.g. 30, 30000/1001);
                       default keeps the source rate, made constant
  -f, --force          overwrite existing outputs
  -n, --dry-run        show what would be converted
  -h, --help           this help

Environment:
  RESOLVE_CONVERT_DIR  default output directory

Intermediate codecs are large: 1080p30 DNxHR HQ is ~80 GB per hour.
EOF
}

die() {
  echo "resolve-convert: $*" >&2
  exit 1
}

log() { echo "resolve-convert: $*" >&2; }

has_word() {
  local w
  for w in $2; do [[ "$w" == "$1" ]] && return 0; done
  return 1
}

lower_ext() {
  local name="${1##*/}"
  [[ "$name" == *.* ]] || return 0
  name="${name##*.}"
  echo "${name,,}"
}

# Prints one ffmpeg argument per line for the given preset.
video_args() {
  case "$1" in
    dnxhr-lb) printf '%s\n' -c:v dnxhd -profile:v dnxhr_lb -pix_fmt yuv422p ;;
    dnxhr-sq) printf '%s\n' -c:v dnxhd -profile:v dnxhr_sq -pix_fmt yuv422p ;;
    dnxhr-hq) printf '%s\n' -c:v dnxhd -profile:v dnxhr_hq -pix_fmt yuv422p ;;
    dnxhr-hqx) printf '%s\n' -c:v dnxhd -profile:v dnxhr_hqx -pix_fmt yuv422p10le ;;
    dnxhr-444) printf '%s\n' -c:v dnxhd -profile:v dnxhr_444 -pix_fmt yuv444p10le ;;
    prores-lt) printf '%s\n' -c:v prores_ks -profile:v lt -pix_fmt yuv422p10le -vendor apl0 ;;
    prores) printf '%s\n' -c:v prores_ks -profile:v standard -pix_fmt yuv422p10le -vendor apl0 ;;
    prores-hq) printf '%s\n' -c:v prores_ks -profile:v hq -pix_fmt yuv422p10le -vendor apl0 ;;
    prores-4444) printf '%s\n' -c:v prores_ks -profile:v 4444 -pix_fmt yuva444p10le -vendor apl0 ;;
    *) die "unknown preset '$1' (see --help)" ;;
  esac
}

# Sets: P_VCODEC P_PIXFMT P_ACODECS (space-separated, one per audio stream).
# Returns 1 for files that aren't usable media (images, broken files, ...).
probe() {
  local json
  json="$(ffprobe -v error -show_entries stream=codec_type,codec_name,pix_fmt:stream_disposition=attached_pic:format=format_name -of json -- "$1" 2>/dev/null)" ||
    return 1

  # Still images probe as single-frame "video"; they import into Resolve as-is.
  jq -e '.format.format_name | test("image2|_pipe$")' >/dev/null <<<"$json" && return 1

  P_VCODEC="$(jq -r '[.streams[] | select(.codec_type == "video" and (.disposition.attached_pic // 0) == 0)][0] | .codec_name // ""' <<<"$json")"
  P_PIXFMT="$(jq -r '[.streams[] | select(.codec_type == "video" and (.disposition.attached_pic // 0) == 0)][0] | .pix_fmt // ""' <<<"$json")"
  P_ACODECS="$(jq -r '[.streams[] | select(.codec_type == "audio") | .codec_name] | join(" ")' <<<"$json")"
  [[ -n "$P_VCODEC" || -n "$P_ACODECS" ]]
}

# Converts $1 to $2. Prints a one-line plan; returns non-zero on failure.
convert() {
  local src="$1" dst="$2" preset="$PRESET"
  local -a args=(-hide_banner -nostdin -loglevel error -stats -i "$src" -map_metadata 0)
  local plan=""

  if [[ -n "$P_VCODEC" ]]; then
    args+=(-map 0:V:0)
    if has_word "$P_VCODEC" "$VIDEO_OK"; then
      args+=(-c:v copy)
      plan="video: copy ($P_VCODEC)"
    else
      if [[ "$preset" == auto ]]; then
        # yuv420p10le, p010le, yuv422p12le, gbrp10le, ... -> keep the extra
        # bits. (>8-bit formats always carry an endianness suffix; nv12 doesn't.)
        if [[ "$P_PIXFMT" =~ (9|10|12|14|16)(le|be)$ ]]; then
          preset=dnxhr-hqx
        else
          preset=dnxhr-hq
        fi
      fi
      local -a vargs=()
      mapfile -t vargs < <(video_args "$preset")
      args+=("${vargs[@]}" -fps_mode cfr)
      [[ -n "$FPS" ]] && args+=(-r "$FPS")
      plan="video: $P_VCODEC -> $preset"
    fi
  fi

  if [[ -n "$P_ACODECS" ]]; then
    args+=(-map '0:a')
    local i=0 c aplan=""
    for c in $P_ACODECS; do
      if [[ "$c" == pcm_* ]]; then
        args+=("-c:a:$i" copy)
      else
        args+=("-c:a:$i" pcm_s24le)
        aplan="$c -> pcm_s24le"
      fi
      i=$((i + 1))
    done
    plan="${plan:+$plan, }audio: ${aplan:-copy (pcm)}"
  fi

  if $DRY_RUN; then
    echo "$src -> $dst  [$plan]"
    return 0
  fi

  log "$src  [$plan]"
  mkdir -p "$(dirname "$dst")"
  # Write to a hidden temp file so a partial result never looks finished.
  local tmp
  tmp="$(dirname "$dst")/.partial.$(basename "$dst")"
  CURRENT_TMP="$tmp"
  if ffmpeg "${args[@]}" -y "$tmp"; then
    mv -f "$tmp" "$dst"
    CURRENT_TMP=""
    return 0
  fi
  rm -f "$tmp"
  CURRENT_TMP=""
  return 1
}

# Converts one file; $2 is its path relative to the output directory, minus
# the extension.
handle() {
  local src="$1" rel="$2" dst
  if ! probe "$src"; then
    log "skipping $src (not audio/video)"
    SKIPPED=$((SKIPPED + 1))
    return
  fi
  if [[ -n "$P_VCODEC" ]]; then dst="$OUT_DIR/$rel.mov"; else dst="$OUT_DIR/$rel.wav"; fi

  if [[ -e "$dst" ]] && ! $FORCE; then
    log "skipping $src ($dst exists; --force to overwrite)"
    SKIPPED=$((SKIPPED + 1))
    return
  fi
  if convert "$src" "$dst"; then
    DONE=$((DONE + 1))
  else
    log "FAILED: $src"
    FAILED+=("$src")
  fi
}

# ── main ───────────────────────────────────────────────────────────────────

OUT_DIR="${RESOLVE_CONVERT_DIR:-$DEFAULT_OUT_DIR}"
PRESET=auto
FPS=""
FORCE=false
DRY_RUN=false
declare -a INPUTS=()

while (($#)); do
  case "$1" in
    -o | --output) OUT_DIR="${2:?$1 needs a directory}"; shift 2 ;;
    -p | --preset) PRESET="${2:?$1 needs a value}"; shift 2 ;;
    --fps) FPS="${2:?--fps needs a value}"; shift 2 ;;
    -f | --force) FORCE=true; shift ;;
    -n | --dry-run) DRY_RUN=true; shift ;;
    -h | --help) usage; exit 0 ;;
    --) shift; INPUTS+=("$@"); break ;;
    -*) die "unknown option '$1' (see --help)" ;;
    *) INPUTS+=("$1"); shift ;;
  esac
done

((${#INPUTS[@]})) || { usage >&2; exit 1; }
[[ "$PRESET" == auto ]] || video_args "$PRESET" >/dev/null
OUT_DIR="$(realpath -m -- "$OUT_DIR")"

CURRENT_TMP=""
trap '[[ -n "$CURRENT_TMP" ]] && rm -f "$CURRENT_TMP"' EXIT
trap 'exit 130' INT TERM

DONE=0
SKIPPED=0
declare -a FAILED=()

for input in "${INPUTS[@]}"; do
  if [[ -d "$input" ]]; then
    root="$(realpath -- "$input")"
    [[ "$OUT_DIR" == "$root" || "$OUT_DIR" == "$root"/* ]] &&
      die "output directory $OUT_DIR is inside input $root; pick another with -o"
    while IFS= read -r -d '' f; do
      has_word "$(lower_ext "$f")" "$VIDEO_EXTS $AUDIO_EXTS" || continue
      rel="${f#"$root"/}"
      handle "$f" "$(basename "$root")/${rel%.*}"
    done < <(find "$root" -type f -not -name '.*' -print0 | sort -z)
  elif [[ -f "$input" ]]; then
    name="$(basename -- "$input")"
    handle "$input" "${name%.*}"
  else
    log "no such file or directory: $input"
    FAILED+=("$input")
  fi
done

if ! $DRY_RUN; then
  log "done: $DONE converted, $SKIPPED skipped, ${#FAILED[@]} failed -> $OUT_DIR"
fi
((${#FAILED[@]} == 0))
