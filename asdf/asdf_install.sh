#!/bin/zsh

asdf current | tail -n +2 | while read -r line; do
  # ignore empty lines
  [[ -z "${line// }" ]] && continue

  plugin="$(awk '{print $1}' <<<"$line")"
  version="$(awk '{print $2}' <<<"$line")"
  installed="$(awk '{print $4}' <<<"$line")"

  asdf plugin add "$plugin"
  asdf install "$plugin" "$version"
done

## Global bin packages
# golang

go_packages=(
  "github.com/nametake/golangci-lint-langserver@latest"
)

for package in "${go_packages[@]}"; do
  go install "$package"
done

asdf reshim golang

# npm

npm_packages=(
  "vscode-langservers-extracted"
  "@zed-industries/claude-code-acp"
  "@github/copilot-language-server-darwin-arm64"
)

npm install -g "${npm_packages[@]}"

asdf reshim nodejs

# corepack enable
# asdf reshim nodejs
