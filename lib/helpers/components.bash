#!/usr/bin/env bash
# shellcheck shell=bash

# Note: arrays cannot be exported in bash — don't use `export` here.
# The array is available in the current shell and subshells (fork inherits).
GAUDI_SHELL_COMPONENT_TYPES=(plugins aliases completions)

__check-function-parameters() {
	[[ -z "$1" ]] && return 1
	# Ensure the component types array is populated (defensive — cannot rely
	# on array export surviving across bats `run` or other subshell boundaries).
	local -a _types=("${GAUDI_SHELL_COMPONENT_TYPES[@]}")
	((${#_types[@]})) || _types=(plugins aliases completions)
	_array-contains "$(_gaudi-shell-pluralize-component "${1}")" "${_types[@]}" && return 0
	return 1
}

_gaudi-shell-pluralize-component() {
	local component="${1}"
	local len=$((${#component} - 1))
	[[ -n $component ]] || return 1
	[[ ${component:${len}:1} != 's' ]] && component="${component}s"
	[[ ${component} == "alias" ]] && component="aliases"
	printf "%s" "${component}"
}

_gaudi-shell-singularize-component() {
	local component="${1}"
	[[ -n "$component" ]] || return 1
	local plural
	plural="$(_gaudi-shell-pluralize-component "$component")"
	local component_singular
	[[ "$plural" == *ies ]] && component_singular=${plural%ies} && {
		printf "%s" "${component_singular}y"
		return 0
	}
	[[ "$plural" == *es ]] && component_singular=${plural%es}
	[[ "$plural" == *ns ]] && component_singular=${plural%s}
	printf "%s" "${component_singular:-$plural}"
}

_gaudi-shell-component-help() {
	__check-function-parameters "$1" || return 1
	local type component
	type=$(_gaudi-shell-pluralize-component "${1}")
	component="$2"
	help=$(_gaudi-shell-describe "$type" | tail -n +4)
	if [[ -n $component ]]; then
		printf "%s" "$help" | grep "${component}" && return 0
		return 1
	fi
	printf "%s" "${help}"
}

_gaudi-shell-component-list() {
	__check-function-parameters "$1" || return 1
	_gaudi-shell-component-help "$1" | awk '{print $1}' | uniq | sort | tr '\n' ' '
}

_gaudi-shell-component-list-matching() {
	__check-function-parameters "$1" || return 1
	if [[ -n "$1" ]] && [[ -n "$2" ]]; then
		local match
		match=$(_gaudi-shell-component-help "$1" | $GAUDI_SHELL_GREP -E -- "$2" | awk '{print $1}' | uniq | sort | tr '\n' ' ')
		[[ -n "$match" ]] && echo "$match" && return 0
	fi
	return 1
}

_gaudi-shell-component-list-enabled() {
	__check-function-parameters "$1" || return 1
	_gaudi-shell-component-help "${1}" | $GAUDI_SHELL_GREP -E '◉' | awk '{print $1}' | uniq | sort | tr '\n' ' '
}

_gaudi-shell-component-list-disabled() {
	__check-function-parameters "$1" || return 1
	_gaudi-shell-component-help "${1}" | $GAUDI_SHELL_GREP -E '◯' | awk '{print $1}' | uniq | sort | tr '\n' ' '
}

_gaudi-shell-component-item-is-enabled() {
	__check-function-parameters "$1" || return 1
	if [[ -n "$1" ]] && [[ -n "$2" ]]; then
		_gaudi-shell-component-list-enabled "$1" | tr ' ' '\n' | $GAUDI_SHELL_GREP -E -q -- "^${2}$"
	else
		return 1
	fi
}

_gaudi-shell-component-item-is-disabled() {
	__check-function-parameters "$1" || return 1
	if [[ -n "$1" ]] && [[ -n "$2" ]]; then
		_gaudi-shell-component-list-disabled "$1" | tr ' ' '\n' | $GAUDI_SHELL_GREP -E -q -- "^${2}$"
	else
		return 1
	fi
}
