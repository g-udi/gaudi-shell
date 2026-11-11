#!/usr/bin/env bash
# shellcheck shell=bash

_command_exists() {
	local msg="${2:-"command $1 does not exist!"}"
	type "$1" &>/dev/null || {
		_log_error "$msg"
		return 1
	}
}

# True when $1 is an executable file found on PATH. Shell functions, aliases
# and builtins do not count (use _command_exists for those): components rely on
# this to look past lazy-load stubs such as the nvm plugin's npm function.
_binary_exists() {
	local msg="${2:-Binary $1 does not exist}"
	if [[ -n "${ZSH_VERSION:-}" ]]; then
		whence -p -- "$1" >/dev/null && return 0
	elif type -P "$1" >/dev/null; then
		return 0
	fi
	_log_debug "$msg"
	return 1
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

# True when Homebrew is installed; its prefix is then in
# GAUDI_HOST_HOMEBREW_PREFIX (the name components use, see the host contract
# below) and in GAUDI_SHELL_HOMEBREW_PREFIX. `brew --prefix` runs once at most.
_homebrew-check() {
	if _binary_exists 'brew'; then
		: "${GAUDI_HOST_HOMEBREW_PREFIX:=${GAUDI_SHELL_HOMEBREW_PREFIX:-$(brew --prefix)}}"
		GAUDI_SHELL_HOMEBREW_PREFIX="$GAUDI_HOST_HOMEBREW_PREFIX"
		export GAUDI_SHELL_HOMEBREW_PREFIX GAUDI_HOST_HOMEBREW_PREFIX
		return 0
	fi
	GAUDI_SHELL_HOMEBREW_PREFIX=
	GAUDI_HOST_HOMEBREW_PREFIX=
	return 1
}

# Component host contract
# -----------------------
# The files under components/aliases, components/completions and
# components/plugins are shared, byte for byte, with gaudi-bash. They never
# name a framework: they use only the names below, which each framework
# defines once (gaudi-bash does it in its own lib/helpers/utils.bash), plus
# the helpers both frameworks already share:
#   cite, about, about-alias, about-plugin, about-completion, group, param,
#   example, priority               (lib/composure.bash)
#   _log_debug, _log_warning, _log_error                    (lib/log.bash)
#   pathmunge                                    (lib/helpers/generic.bash)
#   _command_exists, _binary_exists, _homebrew-check          (this file)
#
#   GAUDI_HOST_NAME              the framework's name, for messages and cache folders
#   GAUDI_HOST_COMMAND           the command its users type
#   GAUDI_HOST_HOME              its install directory (components/enabled and
#                                components/custom live under it)
#   GAUDI_HOST_SED_I_PARAMETERS  array: the arguments that make sed edit in place on this OS
#   GAUDI_HOST_HOMEBREW_PREFIX   the Homebrew prefix; empty until _homebrew-check
#                                (or the brew plugin) has found it
#   _gaudi_host_setting NAME     prints the user's setting NAME (HTTP_PROXY, THEME, ...)
# shellcheck disable=SC2034
GAUDI_HOST_NAME="gaudi-shell"
# shellcheck disable=SC2034
GAUDI_HOST_COMMAND="gshell"
# shellcheck disable=SC2034
GAUDI_HOST_HOME="${GAUDI_SHELL:-}"
# shellcheck disable=SC2034
GAUDI_HOST_SED_I_PARAMETERS=("${GAUDI_SHELL_SED_I_PARAMETERS[@]}")
: "${GAUDI_HOST_HOMEBREW_PREFIX:=${GAUDI_SHELL_HOMEBREW_PREFIX:-}}"

# Print the value of the user setting $1 (capitals, digits and "_" only), read
# when called: GAUDI_<name> if set, otherwise this framework's
# GAUDI_SHELL_<name>, otherwise nothing.
_gaudi_host_setting() {
	case "${1:-}" in
	"" | *[!A-Z0-9_]*) return 1 ;;
	esac
	eval "printf '%s' \"\${GAUDI_$1:-\${GAUDI_SHELL_$1:-}}\""
}
