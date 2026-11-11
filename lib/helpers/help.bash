#!/usr/bin/env bash
# shellcheck shell=bash

# For every enabled component of type $1 (aliases, plugins), print its name and
# the lines of its file that match the extended regular expression $2.
_gaudi-shell-help-components() {
	local type="$1" pattern="$2" __file name width
	width="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
	for __file in "${GAUDI_SHELL}"/components/enabled/*."${type}".bash; do
		[[ -f "$__file" ]] || continue
		name="${__file##*/}"
		name="${name#*"${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}"}"
		name="${name%."${type}".bash}"
		printf '\n\n%s\n' "${GREEN}${name}${NC}"
		printf '%*s\n' "$width" '' | tr ' ' -
		grep -E "$pattern" "$__file" 2>/dev/null
	done
}

_help-aliases() {
	_gaudi-shell-help-components aliases '^alias '
}

_help-plugins() {
	_gaudi-shell-help-components plugins '^[a-z_-]+\s*\(\)'
}

_help-completions() {
	_gaudi-shell-describe completions enabled
}
