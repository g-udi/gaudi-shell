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
			case "${_gaudi_shell_dangling##*.}" in
			aliases) _gaudi_shell_dangling="alias ${_gaudi_shell_dangling%.*}" ;;
			plugins) _gaudi_shell_dangling="plugin ${_gaudi_shell_dangling%.*}" ;;
			completions) _gaudi_shell_dangling="completion ${_gaudi_shell_dangling%.*}" ;;
			esac
			printf '%s\n' "gaudi-shell: enabled component '${_gaudi_shell_config_file##*/}' points to a missing file, skipped. Fix: gshell enable ${_gaudi_shell_dangling}" >&2
		fi
	done
fi

unset _gaudi_shell_config_file _gaudi_shell_dangling
unset GAUDI_SHELL_LOG_PREFIX
