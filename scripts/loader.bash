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
		fi
	done
fi

unset _gaudi_shell_config_file
unset GAUDI_SHELL_LOG_PREFIX
