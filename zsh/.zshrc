# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

plugins=(git docker dotenv git-prompt git-auto-fetch asdf)

source $ZSH/oh-my-zsh.sh

# Custom zshrc file
if [[ -f "$HOME/.zshrc_profile" ]]; then
	source "$HOME/.zshrc_profile"
fi

alias ll="eza --long --color=always --icons=always --no-filesize --no-user"

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

# yarn global packages
export PATH="$(yarn global bin):$PATH"

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# FZF

# Fuzzy finder key bindings and autocompletion
# - CTRL-R searches in the command line history
# - CTRL-T searches files and directories
# - ALT-C runs cd into a directory
# - **<TAB> autocompletes with fzf
source <(fzf --zsh)

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git "
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_TMUX_OPTS=" -p90%,70% "
# https://github.com/catppuccin/fzf
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--color=border:#313244,label:#cdd6f4"

# Starship
eval "$(starship init zsh)"
export STARSHIP_CONFIG=$HOME/.config/starship/starship.toml

# Podman
# Needs some testing first
# export DOCKER_HOST=unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')
