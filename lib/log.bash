#!/usr/bin/env bash
# shellcheck shell=bash

export GAUDI_SHELL_LOG_LEVEL_ERROR=1
export GAUDI_SHELL_LOG_LEVEL_WARNING=2
export GAUDI_SHELL_LOG_LEVEL_ALL=3

_gaudi-shell-get-component-name-from-path() {
	local file_name component_name
	file_name=${1%.*.bash}
	component_name=${file_name##*/}
	echo "${component_name##*"$GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR"}"
}

_gaudi-shell-get-component-type-from-path() {
	local filename
	filename=${1##*/}
	filename="${filename##*"$GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR"}"
	filename="${filename#*.}"
	filename="${filename%%.*}"
	_gaudi-shell-singularize-component "$filename"
}

_log_general() {
	[[ -z $1 ]] && return
	GAUDI_SHELL_LOG_PREFIX=${GAUDI_SHELL_LOG_PREFIX:-"CORE"}

	local log_type log_prefix output_fd
	log_type=${2:-GENERAL}
	log_prefix="[${GAUDI_SHELL_LOG_PREFIX}]"
	output_fd=1
	[[ "${log_type}" == "ERROR" || "${log_type}" == "WARNING" ]] && output_fd=2

	printf "%s\n" " [ ${log_type} ] ${log_prefix} $1" >&"$output_fd"
}

_log_debug() {
	[[ "${GAUDI_SHELL_LOG_LEVEL:-0}" -ge $GAUDI_SHELL_LOG_LEVEL_ALL ]] || return 0
	_log_general "$1" "DEBUG"
}

_log_warning() {
	[[ "${GAUDI_SHELL_LOG_LEVEL:-0}" -ge $GAUDI_SHELL_LOG_LEVEL_WARNING ]] || return 0
	_log_general "$1" "WARNING"
}

_log_error() {
	[[ "${GAUDI_SHELL_LOG_LEVEL:-0}" -ge $GAUDI_SHELL_LOG_LEVEL_ERROR ]] || return 0
	_log_general "$1" "ERROR"
}

_log_component() {
	[[ "${GAUDI_SHELL_LOG_LEVEL:-0}" -ge $GAUDI_SHELL_LOG_LEVEL_ALL ]] || return 0

	local component_path type component_name component_type
	component_path=${1}
	type=${2:-component}

	if [[ $type = "component" ]]; then
		component_name="$(_gaudi-shell-get-component-name-from-path "$component_path")"
		component_type="$(_gaudi-shell-get-component-type-from-path "$component_path")"
		_log_general "Loading ${component_type}: ${component_name}" "DEBUG"
	else
		component_name=${component_path##*/}
		_log_general "Loading ${type}: ${component_name%*.bash}" "DEBUG"
	fi
}
