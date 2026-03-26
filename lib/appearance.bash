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
	# Check for directory-based theme first (e.g., gaudi/gaudi.theme.bash)
	theme_dir="${GAUDI_SHELL}/components/themes/${GAUDI_SHELL_CURRENT}/${GAUDI_SHELL_THEME}"
	theme_file="${theme_dir}/${GAUDI_SHELL_THEME}.theme.bash"
	if [[ -f "$theme_file" ]]; then
		source "$theme_file"
		_log_component "$GAUDI_SHELL_THEME" "theme"
	# Fallback: single file theme
	elif [[ -f "${theme_dir}.bash" ]]; then
		source "${theme_dir}.bash"
		_log_component "$GAUDI_SHELL_THEME" "theme"
	fi
fi

unset GAUDI_SHELL_LOG_PREFIX
