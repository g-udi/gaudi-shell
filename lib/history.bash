#!/usr/bin/env bash
# shellcheck shell=bash

# History configuration — works in both bash and zsh

# Each shell gets its own command only: in bash an unknown "setopt" would go
# through the command-not-found handler on every start.
if [[ -n "${ZSH_VERSION:-}" ]]; then
	setopt APPEND_HISTORY
else
	shopt -s histappend 2>/dev/null || true
fi

# Defaults only: a value set before gaudi-shell is sourced is kept.
: "${HISTCONTROL:=ignoredups:ignorespace}"

# The shells always define the history sizes themselves (500 in bash, 30 in
# zsh), so ":=" would never apply. Raise a size that is a number below the
# wanted minimum; leave larger values and "unlimited" (negative or empty in
# bash) alone.
_gaudi_shell_history_at_least() {
	local _current
	eval "_current=\"\${$1-0}\""
	case "$_current" in
	"" | *[!0-9]*) return 0 ;;
	esac
	[[ "$_current" -lt "$2" ]] && eval "$1=$2"
	return 0
}

_gaudi_shell_history_at_least HISTSIZE 10000
if [[ -n "${ZSH_VERSION:-}" ]]; then
	# zsh writes nothing without a history file and a SAVEHIST above zero
	: "${HISTFILE:=${ZDOTDIR:-$HOME}/.zsh_history}"
	_gaudi_shell_history_at_least SAVEHIST 20000
else
	_gaudi_shell_history_at_least HISTFILESIZE 20000
fi
unset -f _gaudi_shell_history_at_least
