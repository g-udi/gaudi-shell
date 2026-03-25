#!/usr/bin/env zsh
#
# gaudi-shell zsh adapter
#
# Source this from your ~/.zshrc:
#   export GAUDI_SHELL="$HOME/.gaudi-shell"
#   source "$GAUDI_SHELL/adapters/zsh/init.zsh"

: "${GAUDI_SHELL:=${0:A:h}/../..}"

# Enable bash-compatible features needed for POSIX core
setopt SH_WORD_SPLIT 2>/dev/null
setopt KSH_ARRAYS 2>/dev/null

# Load POSIX core
. "$GAUDI_SHELL/core/registry.sh"
. "$GAUDI_SHELL/core/loader.sh"
. "$GAUDI_SHELL/core/profiles.sh"
. "$GAUDI_SHELL/core/cli.sh"

# Load all enabled components
gaudi_load_components

# Finalize hooks
for _gaudi_hook in "${GAUDI_SHELL_FINALIZE_HOOKS[@]}"; do
    "$_gaudi_hook"
done
unset _gaudi_hook

# Restore zsh defaults
unsetopt SH_WORD_SPLIT 2>/dev/null
unsetopt KSH_ARRAYS 2>/dev/null
