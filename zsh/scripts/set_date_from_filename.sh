set_date_from_filename() {
  if ! command -v exiftool >/dev/null 2>&1; then
    echo "Error: exiftool is required but not installed."
    echo "Install it with:"
    echo "  macOS: brew install exiftool"
    echo "  Ubuntu/Debian: sudo apt install libimage-exiftool-perl"
    return 1
  fi

  if [ "$#" -eq 0 ]; then
    echo "Usage: set_date_from_filename <video-file> [video-file ...]"
    return 1
  fi

  local file filename datetime
  local year month day hour minute second

  for file in "$@"; do
    filename="${file:t}"
    datetime=""

    # Pattern with date + time:
    #   20260613_200512918
    #   20260613-200512
    #   20260613200512
    #
    # Uses the first 6 time digits as HHMMSS.
    if [[ "$filename" =~ '([0-9]{4})([0-9]{2})([0-9]{2})[-_]?([0-9]{2})([0-9]{2})([0-9]{2})' ]]; then
      year="${match[1]}"
      month="${match[2]}"
      day="${match[3]}"
      hour="${match[4]}"
      minute="${match[5]}"
      second="${match[6]}"

      datetime="${year}:${month}:${day} ${hour}:${minute}:${second}"

    # Pattern with date only:
    #   20260615
    elif [[ "$filename" =~ '([0-9]{4})([0-9]{2})([0-9]{2})' ]]; then
      year="${match[1]}"
      month="${match[2]}"
      day="${match[3]}"

      datetime="${year}:${month}:${day} 00:00:00"

    else
      echo "Skipping: $file"
      echo "  Could not find a YYYYMMDD date in filename."
      continue
    fi

    echo "Updating: $file"
    echo "  Date: $datetime"

    exiftool \
      -overwrite_original \
      "-CreateDate=$datetime" \
      "-ModifyDate=$datetime" \
      "-MediaCreateDate=$datetime" \
      "-MediaModifyDate=$datetime" \
      "-TrackCreateDate=$datetime" \
      "-TrackModifyDate=$datetime" \
      "$file"
  done
}
