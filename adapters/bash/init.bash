#!/usr/bin/env bash
# shellcheck shell=bash
#
# gaudi-shell bash adapter
#
# Add to your ~/.bash_profile or ~/.bashrc:
#   export GAUDI_SHELL="$HOME/.gaudi-shell"
#   source "$GAUDI_SHELL/adapters/bash/init.bash"

# An absolute path, so the commands keep working after a cd
: "${GAUDI_SHELL:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

source "$GAUDI_SHELL/gaudi_shell.sh"
