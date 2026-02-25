#!/usr/bin/env bash

function flac_to_mp3 () {
  for f in "$@"
  do
    output_file="${f%.*}.mp3"
    ffmpeg -i "$f" -map 0:a -c:a libmp3lame -ab 320k -map_metadata 0 -id3v2_version 3 "$output_file"
  done
}

