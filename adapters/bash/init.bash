#!/usr/bin/env bash
# shellcheck shell=bash
#
# gaudi-shell bash adapter
#
# Source this from your ~/.bash_profile or ~/.bashrc:
#   export GAUDI_SHELL="$HOME/.gaudi-shell"
#   source "$GAUDI_SHELL/adapters/bash/init.bash"

: "${GAUDI_SHELL:=${BASH_SOURCE%/*}/../..}"

# Load POSIX core
. "$GAUDI_SHELL/core/registry.sh"
. "$GAUDI_SHELL/core/loader.sh"
. "$GAUDI_SHELL/core/profiles.sh"
. "$GAUDI_SHELL/core/cli.sh"

# Load all enabled components (sorted by priority via glob)
gaudi_load_components

# Finalize hooks (for plugins that need everything loaded)
for _gaudi_hook in "${GAUDI_SHELL_FINALIZE_HOOKS[@]}"; do
    "$_gaudi_hook"
done
unset _gaudi_hook
