#!/usr/bin/env bash

source ~/.tmux/utils/dev-session.sh

selected=$(select_dev_project)

start_dev_session "$selected"
