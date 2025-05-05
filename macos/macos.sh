# Change keyboard repeat rate (to move faster in nvim)
# https://apple.stackexchange.com/questions/10467/how-to-increase-keyboard-key-repeat-rate-on-os-x
defaults write -g KeyRepeat -int 2 # normal minimum is 2 (30 ms)

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Disable automatic arrangement of spaces based on most recent use
defaults write com.apple.dock "mru-spaces" -bool "false"
