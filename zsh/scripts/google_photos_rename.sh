# ~/scripts/google_photos_rename.sh
# Source this file, then run:
#   google_photos_rename [--dry-run]

google_photos_rename() {
  # Don't use "set -e" in sourced functions (can exit your shell)
  set -u
  set -o pipefail 2>/dev/null || true

  local LOG_PREFIX="[gphotos-rename]"
  local DRY_RUN=false
  log() { echo "${LOG_PREFIX} $*"; }

  # Zsh vs Bash glob/array behavior
  if [[ -n "${ZSH_VERSION-}" ]]; then
    # null_glob: unmatched globs disappear
    # ksh_arrays: make arrays 0-indexed (so matches[0] works like bash)
    setopt local_options null_glob ksh_arrays
  else
    shopt -s nullglob 2>/dev/null || true
  fi

  # Parse arguments
  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=true ;;
      *)
        log "Unknown argument: $arg"
        log "Usage: google_photos_rename [--dry-run]"
        return 1
        ;;
    esac
  done

  if ! command -v jq >/dev/null 2>&1; then
    log "ERROR: 'jq' is not installed. Install it (brew install jq / apt-get install jq)."
    return 1
  fi

  # Use UTC to match Google Photos timestamps (change to "" for local time)
  local DATE_TZ_ARGS="-u"

  format_epoch() {
    local epoch="$1"
    if date -u -r 0 +"%Y" >/dev/null 2>&1; then
      date ${DATE_TZ_ARGS} -r "$epoch" +"%Y-%m-%d-%H%M"   # macOS/BSD
    else
      date ${DATE_TZ_ARGS} -d "@$epoch" +"%Y-%m-%d-%H%M" # GNU
    fi
  }

  log "Starting in directory: $(pwd)"
  log "Dry-run mode: $DRY_RUN"
  log "Looking for non-JSON files to rename..."

  local f
  for f in *; do
    [[ -f "$f" ]] || continue
    [[ "$f" == *.json ]] && continue

    log "------------------------------------------------------------"
    log "Processing file: $f"

    # Skip already-processed files
    if [[ "$f" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
      log "File already starts with YYYY-MM-DD. Skipping."
      continue
    fi

    # Find metadata JSON(s)
    local matches=( "${f}"*.json )

    if (( ${#matches[@]} == 0 )); then
      log "No metadata JSON found (pattern: '${f}*.json'). Skipping."
      continue
    fi

    local meta="${matches[0]}"
    if (( ${#matches[@]} > 1 )); then
      log "Multiple metadata JSON files found:"
      local m
      for m in "${matches[@]}"; do log "  - $m"; done
      log "Using: $meta"
    else
      log "Found metadata JSON: $meta"
    fi

    # Extract timestamp
    local ts
    ts="$(jq -r '.photoTakenTime.timestamp // empty' "$meta" 2>/dev/null || true)"
    if [[ -z "$ts" || "$ts" == "null" ]]; then
      log "photoTakenTime.timestamp missing. Falling back to creationTime.timestamp."
      ts="$(jq -r '.creationTime.timestamp // empty' "$meta" 2>/dev/null || true)"
    fi

    if [[ -z "$ts" || "$ts" == "null" ]]; then
      log "ERROR: No usable timestamp found in '$meta'. Skipping '$f'."
      continue
    fi

    if ! [[ "$ts" =~ ^[0-9]+$ ]]; then
      log "ERROR: Timestamp is not numeric ('$ts') in '$meta'. Skipping '$f'."
      continue
    fi

    local stamp
    stamp="$(format_epoch "$ts")" || { log "ERROR: Failed to format epoch '$ts'. Skipping '$f'."; continue; }
    log "Formatted timestamp: $stamp"

    local new="${stamp}-${f}"

    # Avoid overwriting
    if [[ -e "$new" ]]; then
      log "Target '$new' already exists. Resolving conflict..."
      local n=1
      while :; do
        local candidate="${stamp}-dup${n}-${f}"
        if [[ ! -e "$candidate" ]]; then
          new="$candidate"
          break
        fi
        ((n++))
      done
      log "Resolved to: $new"
    fi

    log "Planned rename:"
    log "  FROM: $f"
    log "  TO:   $new"

    if $DRY_RUN; then
      log "DRY-RUN: not renaming."
    else
      if ! mv -v -- "$f" "$new" 2>/dev/null; then
        # Some macOS setups dislike "--"; retry without it
        mv -v "$f" "$new" || { log "ERROR: mv failed for '$f' -> '$new' (continuing)."; continue; }
      fi
    fi
  done

  log "Done."
}

