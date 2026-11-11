#!/usr/bin/env bash
# shellcheck shell=bash

# There are exactly three component types, so both name helpers are a lookup.
# Anything else is passed through the way the old generic code did ("foo"
# becomes "foos"), which callers then reject as an unknown type.
__check-function-parameters() {
	case "$1" in
	alias | aliases | plugin | plugins | completion | completions) return 0 ;;
	esac
	return 1
}

_gaudi-shell-pluralize-component() {
	case "$1" in
	"") return 1 ;;
	alias | aliases) printf "%s" "aliases" ;;
	plugin | plugins) printf "%s" "plugins" ;;
	completion | completions) printf "%s" "completions" ;;
	*s) printf "%s" "$1" ;;
	*) printf "%s" "${1}s" ;;
	esac
}

_gaudi-shell-singularize-component() {
	case "$1" in
	"") return 1 ;;
	alias | aliases) printf "%s" "alias" ;;
	plugin | plugins) printf "%s" "plugin" ;;
	completion | completions) printf "%s" "completion" ;;
	*s) printf "%s" "${1%s}" ;;
	*) printf "%s" "$1" ;;
	esac
}

_gaudi-shell-component-help() {
	__check-function-parameters "$1" || return 1
	local type component help
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

_gaudi-shell-component-item-is-enabled() {
	__check-function-parameters "$1" || return 1
	if [[ -n "$1" ]] && [[ -n "$2" ]]; then
		_gaudi-shell-component-list-enabled "$1" | tr ' ' '\n' | $GAUDI_SHELL_GREP -E -q -- "^${2}$"
	else
		return 1
	fi
}
