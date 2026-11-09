#!/usr/bin/env bash

uv tool install "beets[lyrics,fetchart,embedart]" --with beets-filetote

# python LSP server
uv tool install basedpyright
