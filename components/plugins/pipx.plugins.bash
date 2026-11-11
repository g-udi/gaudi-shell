# shellcheck shell=bash

cite about-plugin
about-plugin 'Install and Run Python Applications in Isolated Environments'

# pipx installs its executables here: add it to PATH without running pipx
if _binary_exists pipx; then
  pathmunge "${PIPX_BIN_DIR:-$HOME/.local/bin}" after
fi
