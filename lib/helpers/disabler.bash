#!/usr/bin/env bash
# shellcheck shell=bash

_on-disable-callback() {
	local callback=$1_on_disable
	_command_exists "$callback" &>/dev/null && $callback
}

_gaudi-shell-disable() {
	! __check-function-parameters "$1" && printf "${RED}%s${NC}\n" "Please enter a valid component to disable" && return 1

	local type type_singular component

	type=$(_gaudi-shell-pluralize-component "$1")
	type_singular=$(_gaudi-shell-singularize-component "$1")
	component="$2"

	# Disable all
	if [[ "$type" = "alls" ]] && [[ -z "$component" ]]; then
		_read_input "This will disable all components. Are you sure? [yY/nN]"
		if [[ $REPLY =~ ^[yY]$ ]]; then
			for file_type in "aliases" "plugins" "completions"; do
				_gaudi-shell-disable "$file_type" "all"
			done
		fi
		return 0
	fi

	if [[ "$component" = "all" ]]; then
		find "${GAUDI_SHELL}/components/enabled" -name "*.${type}.bash" -exec rm {} \;
	else
		[[ -z "$component" ]] && printf "${RED}%s ${GREEN}$type_singular(s) ${RED}%s${NC}\n" "Please enter a valid" "to disable" && return 1

		local _component
		_component=$(command ls "${GAUDI_SHELL}/components/enabled/"[0-9]*"${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}${component}.${type}.bash" 2>/dev/null | head -1)

		if [[ -z "$_component" ]]; then
			printf "${RED}∴${NC} ${CYAN}$component ${NC}%s ${GREEN}$type_singular${NC}\n" "does not appear to be an enabled"
			return 1
		else
			rm "${GAUDI_SHELL}/components/enabled/$(basename "$_component")"
		fi
	fi

	_gaudi-shell-component-cache-clean "${type}"
	printf "${CYAN}%s ${GREEN}$type_singular: ${CYAN}$component${NC}\n" "◯ disabled"

	[[ $type == "plugins" ]] && _on-disable-callback "$component"

	if [[ -n "$GAUDI_SHELL_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE" ]]; then
		_gaudi-shell-reload
	fi
	return 0
}
