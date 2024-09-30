# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

plugins=(git nvm docker dotenv git-prompt)

source $ZSH/oh-my-zsh.sh

# Custom zshrc file
if [[ -f "$HOME/.zshrc_profile" ]]; then
	source "$HOME/.zshrc_profile"
fi

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

function to_gif() {
  for f in "$@"
  do
    output_file="${f%.*}.gif"
    ffmpeg -i "$f" -pix_fmt rgb8 -r 10 "$output_file"
    convert "$output_file" -verbose -coalesce -layers OptimizeFrame "$output_file"
    touch -r "$f" "$output_file"

  done
}

function prefix_date() {
  # Check if at least one argument is passed
  if [ $# -lt 1 ]; then
    echo "Error: At least one file is required."
    echo "Usage: prefix_date file1 [file2 ... fileN]"
    return 1
  fi

  # Initialize a counter for the number of files changed
  local count=0

  # Iterate over all the files passed as arguments
  for file in "$@"; do
    # Check if the file exists
    if [ ! -e "$file" ]; then
      echo "Error: The file '$file' does not exist."
      continue
    fi

    # Get the creation date of the file in YYYY_MM_DD format
    local creation_date=$(stat -f %SB -t %Y_%m_%d "$file")

    # Get the name of the new file with the prefix
    local new_file="${creation_date}_${file}"
    
    # Rename the file
    mv "$file" "$new_file"
    
    # Increment the counter
    count=$((count + 1))
  done

  echo "Prefix added to $count file(s)."
}
