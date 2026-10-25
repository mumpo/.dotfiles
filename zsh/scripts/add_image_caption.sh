add_image_caption() {
    local image_path="$1"

    if [[ -z "$image_path" ]]; then
        echo "Usage: add_image_caption /path/to/image"
        return 1
    fi

    if [[ ! -f "$image_path" ]]; then
        echo "File not found: $image_path"
        return 1
    fi

    local exiftool_path
    exiftool_path="$(command -v exiftool)"

    if [[ -z "$exiftool_path" ]]; then
        echo "ExifTool is not installed."
        echo "Install it with: brew install exiftool"
        return 1
    fi

    # Read existing EXIF ImageDescription.
    local current_description
    current_description="$(
        "$exiftool_path" -s3 -EXIF:ImageDescription -- "$image_path"
    )"

    # Prompt using a native macOS dialog.
    # Passing the current description as argv avoids quoting/interpolation issues.
    local new_description
    new_description="$(
        osascript - "$current_description" <<'APPLESCRIPT'
on run argv
    set currentDescription to item 1 of argv

    try
        set dialogResult to display dialog ¬
            "Image description:" ¬
            default answer currentDescription ¬
            with title "Edit Image Caption" ¬
            buttons {"Cancel", "Save"} ¬
            default button "Save" ¬
            cancel button "Cancel"

        return text returned of dialogResult

    on error number -128
        return "__ADD_IMAGE_CAPTION_CANCELLED__"
    end try
end run
APPLESCRIPT
    )"

    if [[ "$new_description" == "__ADD_IMAGE_CAPTION_CANCELLED__" ]]; then
        return 0
    fi

    # Modify only EXIF:ImageDescription.
    #
    # -P                         preserve filesystem modification time
    # -overwrite_original_in_place
    #                            replace file in place without *_original backup
    "$exiftool_path" \
        -P \
        -overwrite_original_in_place \
        "-EXIF:ImageDescription=$new_description" \
        -- "$image_path"

    local status=$?

    if [[ $status -eq 0 ]]; then
        echo "Caption updated: $image_path"
    fi

    return $status
}
