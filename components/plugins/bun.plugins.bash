# shellcheck shell=bash

cite about-plugin
about-plugin 'Configure Bun install directory and add Bun to PATH'

export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
pathmunge "$BUN_INSTALL/bin"
