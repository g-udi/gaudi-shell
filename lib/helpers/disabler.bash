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

	if [[ "$component" = "all" ]]; then
		find "${GAUDI_SHELL}/components/enabled" -name "*.${type}.bash" -exec rm {} \;
	else
		[[ -z "$component" ]] && printf "${RED}%s ${GREEN}$type_singular(s) ${RED}%s${NC}\n" "Please enter a valid" "to disable" && return 1

		# A dangling link counts too: disabling is how it gets cleaned up.
		local _link _found=""
		for _link in "${GAUDI_SHELL}/components/enabled/"[0-9]*"${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}${component}.${type}.bash"; do
			[[ -e "$_link" || -L "$_link" ]] || continue
			_found="$_link"
			break
		done

		if [[ -z "$_found" ]]; then
			printf "${RED}∴${NC} ${CYAN}$component ${NC}%s ${GREEN}$type_singular${NC}\n" "does not appear to be an enabled"
			return 1
		fi
		rm "$_found"
	fi

	_gaudi-shell-component-cache-clean "${type}"
	printf "${CYAN}%s ${GREEN}$type_singular: ${CYAN}$component${NC}\n" "◯ disabled"

	[[ $type == "plugins" ]] && _on-disable-callback "$component"

	if [[ -n "$GAUDI_SHELL_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE" ]]; then
		_gaudi-shell-reload
	fi
	return 0
}
