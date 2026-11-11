#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC1090,SC2034

GAUDI_SHELL_LOG_PREFIX="LOADER"

if [[ -d "$GAUDI_SHELL/components/enabled" ]]; then
	_log_debug "Loading all enabled components..."
	for _gaudi_shell_config_file in "${GAUDI_SHELL}"/components/enabled/*.bash; do
		if [[ -e "${_gaudi_shell_config_file}" ]]; then
			_log_component "$_gaudi_shell_config_file"
			source "$_gaudi_shell_config_file"
		elif [[ -L "${_gaudi_shell_config_file}" ]] &&
			[[ $- == *i* || "${GAUDI_SHELL_LOG_LEVEL:-0}" -ge "${GAUDI_SHELL_LOG_LEVEL_WARNING:-2}" ]]; then
			# Dangling link: its target moved or was removed. Say so once per
			# link instead of skipping it silently (interactive shells, and
			# "gshell doctor" runs, only: scripts stay quiet).
			_gaudi_shell_dangling="${_gaudi_shell_config_file##*"${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}"}"
			_gaudi_shell_dangling="${_gaudi_shell_dangling%.bash}"
			_gaudi_shell_dangling_type="${_gaudi_shell_dangling##*.}"
			_gaudi_shell_dangling="${_gaudi_shell_dangling%.*}"
			if _gaudi-shell-component-file "$_gaudi_shell_dangling_type" "$_gaudi_shell_dangling" >/dev/null || ! _gaudi-shell-component-submodules-present; then
				# The component is there (or the shared components were never
				# fetched): the link is from an older layout or another
				# install directory, and "gshell migrate" rewrites it.
				_gaudi_shell_dangling="gshell migrate"
			else
				_gaudi_shell_dangling="gshell enable $(_gaudi-shell-singularize-component "$_gaudi_shell_dangling_type") ${_gaudi_shell_dangling}"
			fi
			printf '%s\n' "gaudi-shell: enabled component '${_gaudi_shell_config_file##*/}' points to a missing file, skipped. Fix: ${_gaudi_shell_dangling}" >&2
		fi
	done
fi

unset _gaudi_shell_config_file _gaudi_shell_dangling _gaudi_shell_dangling_type
unset GAUDI_SHELL_LOG_PREFIX
