#!/usr/bin/env bash
# shellcheck shell=bash

_help-aliases() {
	local __file
	for __file in "${GAUDI_SHELL}"/components/enabled/*.aliases.bash; do
		[[ -f "$__file" ]] || continue
		local file
		file=$(basename "$__file" | sed -e 's/[0-9]*[___]*\(.*\)\.aliases\.bash/\1/g')
		printf '\n\n%b\n' "${GREEN}${file}${NC}"
		printf '%*s\n' "${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}" '' | tr ' ' -
		grep "^alias " "$__file" 2>/dev/null | sed "s/$//"
	done
}

_help-plugins() {
	local __file
	for __file in "${GAUDI_SHELL}"/components/enabled/*.plugins.bash; do
		[[ -f "$__file" ]] || continue
		local file
		file=$(basename "$__file" | sed -e 's/[0-9]*[___]*\(.*\)\.plugins\.bash/\1/g')
		printf '\n\n%b\n' "${GREEN}${file}${NC}"
		printf '%*s\n' "${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}" '' | tr ' ' -
		grep -E '^[a-z_-]+\s*\(\)' "$__file" 2>/dev/null
	done
}

_help-completions() {
	_gaudi-shell-describe completions enabled
}
