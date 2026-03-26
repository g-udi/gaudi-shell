#!/usr/bin/env bash
# shellcheck shell=bash

# Cache directory: prefer XDG_CACHE_HOME, fall back to ~/.cache
GAUDI_SHELL_CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/gaudi-shell"

_gaudi-shell-component-cache-add() {
	[[ -z $1 ]] && return 1
	local file="${GAUDI_SHELL_CACHE_DIR}/${1}"
	[[ -f ${file} ]] || mkdir -p "${file%/*}"
	printf "%s" "${file}"
}

_gaudi-shell-component-cache-clean() {
	local component="$1"
	local cache
	declare -a GAUDI_SHELL_COMPONENTS=(aliases plugins completions)

	if [[ -z ${component} ]]; then
		for component in "${GAUDI_SHELL_COMPONENTS[@]}"; do
			_gaudi-shell-component-cache-clean "${component}"
		done
	else
		cache=$(_gaudi-shell-component-cache-add "${component}")
		if [[ -f "${cache}" ]]; then
			rm -f "${cache}" && rm -f "${cache}-enabled"
		fi
	fi
}
