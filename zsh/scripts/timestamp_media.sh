#!/usr/bin/env bash
# Version: v3 - adds GIF support and ignores zero/placeholder metadata dates

# Source this file from Bash:
#   source ./timestamp_media_v3.sh
#
# Usage:
#   timestamp_media [-y|--yes] FILE [FILE ...]
#
# Options:
#   -y, --yes   Automatically accept inferred dates; do not prompt.
#   --          Stop parsing options. Useful if a filename begins with '-'.
#
# Recognized filename prefixes:
#   YYYY-MM-DD          -> YYYY:MM:DD 00:00:00
#   YYYY-MM-DD-hhmm     -> YYYY:MM:DD hh:mm:00
#
# Supported media types:
#   JPEG (.jpg/.jpeg, any extension case)
#   HEIC/HEIF
#   PNG
#   GIF
#   MP4
#   MOV
#
# Metadata written:
#   JPEG/HEIC/HEIF:
#     EXIF:DateTimeOriginal
#     EXIF:CreateDate
#
#   PNG:
#     PNG:CreationTime
#     XMP:DateCreated
#
#   GIF:
#     XMP:DateCreated
#
#   MP4/MOV:
#     QuickTime:CreateDate
#     QuickTime:TrackCreateDate
#     QuickTime:MediaCreateDate
#
# Requires: exiftool

timestamp_media() {
    if ! command -v exiftool >/dev/null 2>&1; then
        echo "timestamp_media: exiftool is not installed or not in PATH." >&2
        return 1
    fi

    local auto_yes=0
    local file file_type existing_date filename
    local date_part time_part parsed metadata_date display_date reply

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
                printf 'timestamp_media: unknown option: %s\n' "$1" >&2
                printf 'Usage: timestamp_media [-y|--yes] FILE [FILE ...]\n' >&2
                return 2
                ;;
            *)
                break
                ;;
        esac
    done

    if [ "$#" -eq 0 ]; then
        echo "Usage: timestamp_media [-y|--yes] FILE [FILE ...]" >&2
        return 2
    fi

    for file in "$@"; do
        if [ ! -f "$file" ]; then
            printf 'Skipping "%s": not a regular file.\n' "$file" >&2
            continue
        fi

        # Check the real file type rather than the extension.
        file_type="$(exiftool -s3 -FileType -- "$file" 2>/dev/null)"
        case "$file_type" in
            JPEG|HEIC|HEIF|PNG|GIF|MP4|MOV)
                ;;
            *)
                printf 'Skipping "%s": unsupported file type "%s" (expected JPEG, HEIC/HEIF, PNG, GIF, MP4, or MOV).\n' \
                    "$file" "${file_type:-unknown}"
                continue
                ;;
        esac

        # Skip files that already have a real capture/creation date.
        # Some MP4/MOV files contain zero-filled placeholder timestamps such as
        # 0000:00:00 00:00:00. These are not real dates and must not cause a skip.
        case "$file_type" in
            MP4|MOV)
                existing_date="$(
                    exiftool -s3 \
                        -QuickTime:CreateDate \
                        -QuickTime:TrackCreateDate \
                        -QuickTime:MediaCreateDate \
                        -- "$file" 2>/dev/null |
                    awk 'NF && $0 !~ /^0000:00:00 00:00:00([.][0-9]+)?([+-][0-9:]+|Z)?$/ { print; exit }'
                )"
                ;;
            PNG)
                existing_date="$(
                    exiftool -s3 \
                        -PNG:CreationTime \
                        -XMP:DateCreated \
                        -- "$file" 2>/dev/null |
                    awk 'NF && $0 !~ /^0000:00:00 00:00:00([.][0-9]+)?([+-][0-9:]+|Z)?$/ { print; exit }'
                )"
                ;;
            GIF)
                existing_date="$(
                    exiftool -s3 \
                        -XMP:DateCreated \
                        -- "$file" 2>/dev/null |
                    awk 'NF && $0 !~ /^0000:00:00 00:00:00([.][0-9]+)?([+-][0-9:]+|Z)?$/ { print; exit }'
                )"
                ;;
            *)
                existing_date="$(
                    exiftool -s3 \
                        -EXIF:DateTimeOriginal \
                        -EXIF:CreateDate \
                        -- "$file" 2>/dev/null |
                    awk 'NF && $0 !~ /^0000:00:00 00:00:00([.][0-9]+)?([+-][0-9:]+|Z)?$/ { print; exit }'
                )"
                ;;
        esac

        if [ -n "$existing_date" ]; then
            printf 'Skipping "%s": capture/creation date already exists (%s).\n' \
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

        # macOS/BSD date: validate date + time and convert to metadata format.
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

        metadata_date="$parsed"

        if [ "$time_part" = "0000" ]; then
            display_date="$date_part 00:00:00"
        else
            display_date="$date_part $(printf '%s' "$time_part" | cut -c1-2):$(printf '%s' "$time_part" | cut -c3-4):00"
        fi

        printf '\nFile: %s\n' "$file"
        printf 'Type: %s\n' "$file_type"
        printf 'Inferred capture/creation date: %s\n' "$display_date"

        if [ "$auto_yes" -eq 1 ]; then
            reply="y"
            printf 'Auto-accepting inferred date (--yes).\n'
        else
            case "$file_type" in
                MP4|MOV)
                    printf 'Set QuickTime creation dates to this date? [y/N] '
                    ;;
                PNG)
                    printf 'Set PNG CreationTime and XMP DateCreated to this date? [y/N] '
                    ;;
                GIF)
                    printf 'Set GIF XMP DateCreated to this date? [y/N] '
                    ;;
                *)
                    printf 'Set EXIF DateTimeOriginal/CreateDate to this date? [y/N] '
                    ;;
            esac
            IFS= read -r reply
        fi

        case "$reply" in
            y|Y)
                case "$file_type" in
                    MP4|MOV)
                        if exiftool \
                            -overwrite_original \
                            "-QuickTime:CreateDate=$metadata_date" \
                            "-QuickTime:TrackCreateDate=$metadata_date" \
                            "-QuickTime:MediaCreateDate=$metadata_date" \
                            -- "$file" >/dev/null; then
                            printf 'Updated "%s".\n' "$file"
                        else
                            printf 'Failed to update "%s".\n' "$file" >&2
                        fi
                        ;;
                    PNG)
                        if exiftool \
                            -overwrite_original \
                            "-PNG:CreationTime=$metadata_date" \
                            "-XMP:DateCreated=$metadata_date" \
                            -- "$file" >/dev/null; then
                            printf 'Updated "%s".\n' "$file"
                        else
                            printf 'Failed to update "%s".\n' "$file" >&2
                        fi
                        ;;
                    GIF)
                        if exiftool \
                            -overwrite_original \
                            "-XMP:DateCreated=$metadata_date" \
                            -- "$file" >/dev/null; then
                            printf 'Updated "%s".\n' "$file"
                        else
                            printf 'Failed to update "%s".\n' "$file" >&2
                        fi
                        ;;
                    *)
                        if exiftool \
                            -overwrite_original \
                            "-EXIF:DateTimeOriginal=$metadata_date" \
                            "-EXIF:CreateDate=$metadata_date" \
                            -- "$file" >/dev/null; then
                            printf 'Updated "%s".\n' "$file"
                        else
                            printf 'Failed to update "%s".\n' "$file" >&2
                        fi
                        ;;
                esac
                ;;
            *)
                printf 'Skipped "%s".\n' "$file"
                ;;
        esac
    done
}
