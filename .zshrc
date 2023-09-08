# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

plugins=(git docker dotenv git-prompt)

source $ZSH/oh-my-zsh.sh

function to_jpg () {
  for f in "$@"
  do
    output_file="${f%.*}.jpg"
    sips -s format jpeg "$f" --out "$output_file"
    touch -r "$f" "$output_file"
  done
}

function compress_video () {
  for f in "$@"
  do
    output_file="${f%.*}_compressed.${f##*.}"
    ffmpeg -i "$f" -vcodec libx264 -crf 28 "$output_file"
    touch -r "$f" "$output_file"
  done
}