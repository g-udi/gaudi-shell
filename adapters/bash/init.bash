#!/usr/bin/env bash
# shellcheck shell=bash
#
# gaudi-shell bash adapter
#
# Add to your ~/.bash_profile or ~/.bashrc:
#   export GAUDI_SHELL="$HOME/.gaudi-shell"
#   source "$GAUDI_SHELL/adapters/bash/init.bash"

: "${GAUDI_SHELL:=${BASH_SOURCE%/*}/../..}"

source "$GAUDI_SHELL/gaudi_shell.sh"
