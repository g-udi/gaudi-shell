#!/usr/bin/env bash
# shellcheck shell=bash

_is_function() {
	declare -F "$1" &>/dev/null
}

_command_exists() {
	local msg="${2:-"command $1 does not exist!"}"
	type "$1" &>/dev/null || { _log_error "$msg"; return 1; }
}

_binary_exists() {
	local msg="${2:-Binary '$1' does not exist}"
	if type -P "$1" >/dev/null; then
		return 0
	else
		_log_debug "$msg"
		return 1
	fi
}

_completion_exists() {
	local msg="${2:-Completion for '$1' already exists}"
	if complete -p "$1" &>/dev/null; then
		_log_debug "$msg"
		return 0
	else
		return 1
	fi
}

_read_input() {
	unset REPLY
	while ! [[ $REPLY =~ ^[yY]$ ]] && ! [[ $REPLY =~ ^[nN]$ ]]; do
		read -rp "${1} " -n 1 </dev/tty
		[[ -n $REPLY ]] && echo ""
	done
}

_array-contains() {
	local e match="$1"
	shift
	for e; do [[ "$e" == "$match" ]] && return 0; done
	return 1
}

_clean-string() {
	local mode=${2:-"all"}
	local text="$1"

	if [[ $mode = "all" ]]; then
		text="${text#"${text%%[![:space:]]*}"}"
		text="${text%"${text##*[![:space:]]}"}"
		printf '%s' "$text"
	elif [[ $mode = "trailing" ]]; then
		text="${text%"${text##*[![:space:]]}"}"
		printf '%s' "$text"
	elif [[ $mode = "leading" ]]; then
		text="${text#"${text%%[![:space:]]*}"}"
		printf '%s' "$text"
	elif [[ $mode = "any" ]]; then
		printf '%s' "${text//[[:space:]]/}"
	fi
}

_array-dedupe() {
	_clean-string "$(echo "$*" | tr ' ' '\n' | sort -u | tr '\n' ' ')" "all"
}

_homebrew-check() {
	if _binary_exists 'brew'; then
		: "${GAUDI_SHELL_HOMEBREW_PREFIX:=$(brew --prefix)}"
		export GAUDI_SHELL_HOMEBREW_PREFIX
		return 0
	fi
	GAUDI_SHELL_HOMEBREW_PREFIX=
	return 1
}
