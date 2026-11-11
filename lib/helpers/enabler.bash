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
	local _load_priority
	_load_priority="GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_$(echo "$type" | tr "[:lower:]" "[:upper:]")"
	component="$2"
	eval "load_priority=\${${_load_priority}}"

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

		# A link whose target is gone (for example after the install directory
		# moved) is not "enabled": drop it so the component can be linked again.
		local existing_component
		for existing_component in "${GAUDI_SHELL}"/components/enabled/[0-9]*"${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}${_component}"; do
			[[ -L "$existing_component" && ! -e "$existing_component" ]] && rm -f "$existing_component"
		done

		if _gaudi-shell-enabled-link "$_component" >/dev/null; then
			printf "${GREEN}$type_singular ${CYAN}$component${NC} %s\n" "is already enabled"
			return 0
		fi

		# Load priority from file if present
		local local_file_priority use_load_priority
		# Check for priority in either format: '# GAUDI_SHELL_LOAD_PRIORITY: NNN' or 'priority "NNN"'
		local_file_priority=$(grep -m1 -E '(GAUDI_SHELL_LOAD_PRIORITY:|priority ")' "${GAUDI_SHELL}/components/$type/$_component" 2>/dev/null | sed 's/.*: *//;s/priority "//;s/".*//')
		use_load_priority=${local_file_priority:-$load_priority}
		# Relative target (resolved from components/enabled), so the links keep
		# working when the install directory is moved or renamed.
		if ! ln -s "../$type/$_component" "${GAUDI_SHELL}/components/enabled/${use_load_priority}${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}${_component}"; then
			printf "${RED}%s ${GREEN}$type_singular ${CYAN}$component${NC}\n" "Failed to enable" >&2
			return 1
		fi
	fi

	_gaudi-shell-component-cache-clean "${type}"
	printf "${GREEN}%s $type_singular: ${CYAN}$component${NC} %s ${RED}$use_load_priority${NC}\n" "◉" "enabled with priority"

	if [[ -n "$GAUDI_SHELL_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE" ]]; then
		_gaudi-shell-reload
	fi
	return 0
}
