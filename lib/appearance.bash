#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC1090,SC2034

GAUDI_SHELL_LOG_PREFIX="THEME"

# Enable coloring
export CLICOLOR=1
export LSCOLORS='cxfxdxgxbxegedabagacad'

# Colored grep
alias grep='grep --color=auto'

# Load the theme if configured
if [[ -n "${GAUDI_SHELL_THEME:-}" ]]; then
	theme_file="${GAUDI_SHELL}/components/themes/${GAUDI_SHELL_CURRENT}/${GAUDI_SHELL_THEME}.${GAUDI_SHELL_CURRENT}"
	if [[ -f "$theme_file" ]]; then
		source "$theme_file"
		_log_component "$GAUDI_SHELL_THEME" "theme"
	fi
fi

unset GAUDI_SHELL_LOG_PREFIX
