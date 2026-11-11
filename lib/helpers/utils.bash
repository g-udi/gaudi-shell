#!/usr/bin/env bash
# shellcheck shell=bash

_command_exists() {
	local msg="${2:-"command $1 does not exist!"}"
	type "$1" &>/dev/null || {
		_log_error "$msg"
		return 1
	}
}

_binary_exists() {
	local msg="${2:-Binary $1 does not exist}"
	if command -v "$1" >/dev/null; then
		return 0
	else
		_log_debug "$msg"
		return 1
	fi
}

# Ask a yes/no question and read the answer (a line) from standard input.
# Sets REPLY and returns 0 for yes, 1 for no. When nothing can be read (end of
# input, no terminal) it stops asking: REPLY is left empty and it returns 2, so
# callers treat it as "not yes". Works in bash and zsh.
_read_input() {
	REPLY=""
	while true; do
		printf '%s ' "$1"
		if ! read -r REPLY; then
			REPLY=""
			printf '\n'
			return 2
		fi
		case "$REPLY" in
		[yY]) return 0 ;;
		[nN]) return 1 ;;
		esac
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
