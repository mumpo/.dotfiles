#!/usr/bin/env bash

function change_creation_date() {
    local INPUT_FILE="$1"
    local NEW_DATE="$2"

    if [[ -z "$INPUT_FILE" || -z "$NEW_DATE" ]]; then
        echo 'Usage: change_creation_date <file> "YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS"'
        return 1
    fi

    if [[ ! -f "$INPUT_FILE" ]]; then
        echo "Error: File does not exist: $INPUT_FILE"
        return 1
    fi

    local EXTENSION
    EXTENSION="${INPUT_FILE##*.}"
    EXTENSION="$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')"

    local DIRNAME BASENAME FILENAME TEMP_FILE
    DIRNAME="$(dirname "$INPUT_FILE")"
    BASENAME="$(basename "$INPUT_FILE")"
    FILENAME="${BASENAME%.*}"
    TEMP_FILE="${DIRNAME}/${FILENAME}_updated.${EXTENSION}"

    case "$EXTENSION" in
        mp4|mov)
            ffmpeg -y \
                -i "$INPUT_FILE" \
                -c copy \
                -metadata creation_time="$NEW_DATE" \
                "$TEMP_FILE" && mv "$TEMP_FILE" "$INPUT_FILE"
            ;;

        jpg|jpeg)
            exiftool \
                -overwrite_original \
                "-DateTimeOriginal=$NEW_DATE" \
                "-CreateDate=$NEW_DATE" \
                "-ModifyDate=$NEW_DATE" \
                "$INPUT_FILE"
            ;;

        png)
            exiftool \
                -overwrite_original \
                "-CreationTime=$NEW_DATE" \
                "-ModifyDate=$NEW_DATE" \
                "$INPUT_FILE"
            ;;

        *)
            echo "Unsupported file type: .$EXTENSION"
            echo "Supported types: mp4, mov, jpg, jpeg, png"
            return 1
            ;;
    esac

    echo "Updated creation date for: $INPUT_FILE"
}
