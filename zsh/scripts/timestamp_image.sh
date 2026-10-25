#!/usr/bin/env bash

# Source this file from Bash:
#   source ./timestamp_image_v4.sh
#
# Usage:
#   timestamp_image [-y|--yes] FILE [FILE ...]
#
# Options:
#   -y, --yes   Automatically accept inferred dates; do not prompt.
#   --          Stop parsing options. Useful if a filename begins with '-'.
#
# Recognized filename prefixes:
#   YYYY-MM-DD          -> YYYY:MM:DD 00:00:00
#   YYYY-MM-DD-hhmm     -> YYYY:MM:DD hh:mm:00
#
# Supported image types:
#   JPEG (.jpg/.jpeg, any extension case)
#   HEIC/HEIF
#
# Requires: exiftool

timestamp_image() {
    if ! command -v exiftool >/dev/null 2>&1; then
        echo "timestamp_image: exiftool is not installed or not in PATH." >&2
        return 1
    fi

    local auto_yes=0
    local file file_type existing_date filename
    local date_part time_part parsed exif_date display_date reply

    # Parse options before file arguments.
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -y|--yes)
                auto_yes=1
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                printf 'timestamp_image: unknown option: %s\n' "$1" >&2
                printf 'Usage: timestamp_image [-y|--yes] FILE [FILE ...]\n' >&2
                return 2
                ;;
            *)
                break
                ;;
        esac
    done

    if [ "$#" -eq 0 ]; then
        echo "Usage: timestamp_image [-y|--yes] FILE [FILE ...]" >&2
        return 2
    fi

    for file in "$@"; do
        if [ ! -f "$file" ]; then
            printf 'Skipping "%s": not a regular file.\n' "$file" >&2
            continue
        fi

        # Check the real file type rather than the extension. This accepts
        # .jpg/.JPG/.jpeg/.JPEG and .heic/.HEIC (and HEIF) naturally.
        file_type="$(exiftool -s3 -FileType -- "$file" 2>/dev/null)"
        case "$file_type" in
            JPEG|HEIC|HEIF)
                ;;
            *)
                printf 'Skipping "%s": unsupported file type "%s" (expected JPEG or HEIC/HEIF).\n' \
                    "$file" "${file_type:-unknown}"
                continue
                ;;
        esac

        # Skip if an EXIF capture/creation date already exists. Explicit EXIF
        # group names avoid accidentally treating QuickTime container dates as
        # the photo's capture date in HEIC files.
        existing_date="$(
            exiftool -s3 -EXIF:DateTimeOriginal -EXIF:CreateDate -- "$file" 2>/dev/null |
            awk 'NF { print; exit }'
        )"

        if [ -n "$existing_date" ]; then
            printf 'Skipping "%s": EXIF date already exists (%s).\n' \
                "$file" "$existing_date"
            continue
        fi

        filename="${file##*/}"
        date_part=""
        time_part=""

        # Prefer YYYY-MM-DD-hhmm if present.
        if printf '%s\n' "$filename" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}([^0-9]|$)'; then
            date_part="$(printf '%s' "$filename" | cut -c1-10)"
            time_part="$(printf '%s' "$filename" | cut -c12-15)"
        elif printf '%s\n' "$filename" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}([^0-9]|$)'; then
            date_part="$(printf '%s' "$filename" | cut -c1-10)"
            time_part="0000"
        else
            printf 'Skipping "%s": filename does not start with YYYY-MM-DD or YYYY-MM-DD-hhmm.\n' "$file"
            continue
        fi

        # macOS/BSD date: validate date + time and convert to EXIF format.
        parsed="$(
            date -j -f '%Y-%m-%d %H%M' "$date_part $time_part" '+%Y:%m:%d %H:%M:00' 2>/dev/null
        )"

        if [ -z "$parsed" ]; then
            if [ "$time_part" = "0000" ]; then
                display_date="$date_part 00:00:00"
            else
                display_date="$date_part $(printf '%s' "$time_part" | cut -c1-2):$(printf '%s' "$time_part" | cut -c3-4):00"
            fi
            printf 'Skipping "%s": invalid date/time "%s".\n' "$file" "$display_date"
            continue
        fi

        exif_date="$parsed"

        if [ "$time_part" = "0000" ]; then
            display_date="$date_part 00:00:00"
        else
            display_date="$date_part $(printf '%s' "$time_part" | cut -c1-2):$(printf '%s' "$time_part" | cut -c3-4):00"
        fi

        printf '\nFile: %s\n' "$file"
        printf 'Inferred date taken: %s\n' "$display_date"

        if [ "$auto_yes" -eq 1 ]; then
            reply="y"
            printf 'Auto-accepting inferred date (--yes).\n'
        else
            printf 'Set EXIF DateTimeOriginal/CreateDate to this date? [y/N] '
            IFS= read -r reply
        fi

        case "$reply" in
            y|Y)
                if exiftool \
                    -overwrite_original \
                    "-EXIF:DateTimeOriginal=$exif_date" \
                    "-EXIF:CreateDate=$exif_date" \
                    -- "$file" >/dev/null; then
                    printf 'Updated "%s".\n' "$file"
                else
                    printf 'Failed to update "%s".\n' "$file" >&2
                fi
                ;;
            *)
                printf 'Skipped "%s".\n' "$file"
                ;;
        esac
    done
}

