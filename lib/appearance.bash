#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC1090,SC2034

GAUDI_SHELL_LOG_PREFIX="THEME"

# Enable coloring
export CLICOLOR=1
# A default only: an LSCOLORS set before gaudi-shell is sourced is kept
: "${LSCOLORS:=cxfxdxgxbxegedabagacad}"
export LSCOLORS

# Colored grep
alias grep='grep --color=auto'

# Load the theme if configured
if [[ -n "${GAUDI_SHELL_THEME:-}" ]]; then
	theme_file=""
	# Check shell-specific theme directory first, then fall back to bash
	for _shell_type in "${GAUDI_SHELL_CURRENT}" "bash"; do
		_theme_dir="${GAUDI_SHELL}/components/themes/${_shell_type}/${GAUDI_SHELL_THEME}"
		if [[ -f "${_theme_dir}/${GAUDI_SHELL_THEME}.theme.bash" ]]; then
			theme_file="${_theme_dir}/${GAUDI_SHELL_THEME}.theme.bash"
			break
		elif [[ -f "${_theme_dir}.bash" ]]; then
			theme_file="${_theme_dir}.bash"
			break
		fi
	done
	unset _shell_type _theme_dir

	if [[ -n "$theme_file" ]]; then
		source "$theme_file"
		_log_component "$GAUDI_SHELL_THEME" "theme"

		# In zsh, PROMPT_COMMAND doesn't run automatically — hook into precmd
		if [[ -n "${ZSH_VERSION:-}" ]]; then
			_gaudi_zsh_precmd() {
				gaudi::prompt
			}
			# Only add once
			if [[ ! " ${precmd_functions[*]} " == *" _gaudi_zsh_precmd "* ]]; then
				precmd_functions+=(_gaudi_zsh_precmd)
			fi
		fi
	fi
fi

unset theme_file
unset GAUDI_SHELL_LOG_PREFIX
