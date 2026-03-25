#!/usr/bin/env zsh
#
# gaudi-shell zsh adapter
#
# Add to your ~/.zshrc:
#   export GAUDI_SHELL="$HOME/.gaudi-shell"
#   source "$GAUDI_SHELL/adapters/zsh/init.zsh"

: "${GAUDI_SHELL:=${0:A:h}/../..}"

# Enable bash compatibility for the core framework
emulate bash -c 'source "$GAUDI_SHELL/gaudi_shell.sh"'
