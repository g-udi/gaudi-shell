#!/usr/bin/env bash
# shellcheck shell=bash

_gaudi-shell-doctor() {
	local mode="${1:-all}"
	local original_level="${GAUDI_SHELL_LOG_LEVEL:-0}"

	case "$mode" in
	errors)
		GAUDI_SHELL_LOG_LEVEL=$GAUDI_SHELL_LOG_LEVEL_ERROR
		;;
	warnings)
		GAUDI_SHELL_LOG_LEVEL=$GAUDI_SHELL_LOG_LEVEL_WARNING
		;;
	all | *)
		GAUDI_SHELL_LOG_LEVEL=$GAUDI_SHELL_LOG_LEVEL_ALL
		;;
	esac

	source "${GAUDI_SHELL}/gaudi_shell.sh"
	GAUDI_SHELL_LOG_LEVEL=$original_level
}
