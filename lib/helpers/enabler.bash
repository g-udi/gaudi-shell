#!/usr/bin/env bash
# shellcheck shell=bash

GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_ALIASES=${GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_ALIASES:-150}
GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_PLUGINS=${GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_PLUGINS:-250}
GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_COMPLETIONS=${GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_COMPLETIONS:-350}

_gaudi-shell-enable() {
	mkdir -p "${GAUDI_SHELL}/components/enabled"

	! __check-function-parameters "$1" && printf "%s\n" "Please enter a valid component to enable" && return 1

	local type type_singular component load_priority

	type=$(_gaudi-shell-pluralize-component "$1")
	type_singular=$(_gaudi-shell-singularize-component "$1")
	local _load_priority="GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_${type^^}"
	component="$2"
	load_priority="${!_load_priority}"

	# Enable all
	if [[ "$type" = "alls" ]] && [[ -z "$component" ]]; then
		_read_input "This will enable all components. Are you sure? [yY/nN]"
		if [[ $REPLY =~ ^[yY]$ ]]; then
			for file_type in "aliases" "plugins" "completions"; do
				_gaudi-shell-enable "$file_type" "all"
			done
		fi
		return 0
	fi

	[[ -z "$component" ]] && printf "${RED}%s${NC}\n" "Please enter a valid $type_singular(s) to enable" && return 1

	if [[ "$component" = "all" ]]; then
		for _component in "${GAUDI_SHELL}/components/$type/"*.bash; do
			_gaudi-shell-enable "$type" "$(basename "$_component" ."$type".bash)"
		done
	else
		local _component
		_component=$(command ls "${GAUDI_SHELL}/components/$type/$component".*bash 2>/dev/null | head -1)

		[[ -z "$_component" ]] && printf "${CYAN}$component ${RED}%s ${GREEN}$type_singular${NC}\n" "does not appear to be an available" && return 1
		_component=$(basename "$_component")

		local enabled_component
		enabled_component=$(compgen -G "${GAUDI_SHELL}/components/enabled/[0-9][0-9][0-9]${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}${_component}" 2>/dev/null | head -1)
		if [[ -n "$enabled_component" ]]; then
			printf "${GREEN}$type_singular ${CYAN}$component${NC} %s\n" "is already enabled"
			return 0
		fi

		# Load priority from file if present
		local local_file_priority use_load_priority
		local_file_priority=$(grep -m1 '# GAUDI_SHELL_LOAD_PRIORITY:' "${GAUDI_SHELL}/components/$type/$_component" 2>/dev/null | sed 's/.*: *//')
		use_load_priority=${local_file_priority:-$load_priority}
		ln -s "${GAUDI_SHELL}/components/$type/$_component" "${GAUDI_SHELL}/components/enabled/${use_load_priority}${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}${_component}"
	fi

	_gaudi-shell-component-cache-clean "${type}"
	printf "${GREEN}%s $type_singular: ${CYAN}$component${NC} %s ${RED}$use_load_priority${NC}\n" "◉" "enabled with priority"

	if [[ -n "$GAUDI_SHELL_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE" ]]; then
		_gaudi-shell-reload
	fi
	return 0
}
