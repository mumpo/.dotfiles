# .dotfiles

My personal .dotfiles

## Pre-requisites

You must have `git`, `oh-my-zsh`, `stow` and `brew` installed.

## Installation

First clone the repository

```shell
git clone git@github.com:mumpo/.dotfiles.git
```

Then run the install script

```bash
cd .dotfiles
source install.sh
```

### Homebrew

Mac packages are installed via Homebrew, and are defined in the `hombrew/Brewfile`. To install them, just run:

```bash
brew bundle
```

### Tmux

After opening `tmux`, you can install the TPM dependencies running Cmd + I
