#!/usr/bin/env bash
# shellcheck shell=bash

_gaudi-shell-profile-save() {
	local profile_name="$1"
	[[ -z "$profile_name" ]] && printf "${RED}%s${NC}\n" "Please provide a profile name" && return 1

	local profile_dir="${GAUDI_SHELL}/profiles"
	local profile_file="${profile_dir}/${profile_name}.gaudi-shell"
	mkdir -p "${profile_dir}"

	if [[ -f "$profile_file" ]]; then
		_read_input "Profile '${profile_name}' already exists. Overwrite? [yY/nN]"
		[[ ! $REPLY =~ ^[yY]$ ]] && printf "${CYAN}%s${NC}\n" "Profile save cancelled" && return 0
	fi

	: >"${profile_file}"
	local _count=0

	for _file in "${GAUDI_SHELL}"/components/enabled/*.bash; do
		[[ ! -e "$_file" ]] && continue
		local _component _type
		_component="${_file##*"$GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR"}"
		_component="${_component%.bash}"
		_type=$(_gaudi-shell-singularize-component "${_component##*.}")
		_component=${_component%%.*}
		printf "%s\n" "${_type} ${_component}" >>"${profile_file}"
		_count=$((_count + 1))
	done

	printf "${GREEN}%s${NC} %s ${CYAN}%s${NC}\n" "Profile saved:" "${_count} component(s) to" "${profile_name}"
}

_gaudi-shell-profile-load() {
	local profile_name="$1"
	[[ -z "$profile_name" ]] && printf "${RED}%s${NC}\n" "Please provide a profile name" && return 1

	local profile_file="${GAUDI_SHELL}/profiles/${profile_name}.gaudi-shell"
	[[ ! -f "$profile_file" ]] && printf "${RED}%s ${CYAN}%s${RED}%s${NC}\n" "Profile" "${profile_name}" " not found" && return 1

	# Validate
	local _line_num=0 _errors=0
	while IFS= read -r line || [[ -n "$line" ]]; do
		_line_num=$((_line_num + 1))
		[[ -z "$line" ]] && continue
		if [[ ! "$line" =~ ^(alias|plugin|completion)[[:space:]]+[a-zA-Z0-9_-]+$ ]]; then
			printf "${RED}%s${NC} %s: %s\n" "Invalid entry" "line ${_line_num}" "${line}"
			_errors=$((_errors + 1))
		fi
	done <"${profile_file}"
	[[ $_errors -gt 0 ]] && printf "${RED}%s${NC}\n" "Profile validation failed" && return 1

	printf "${MAGENTA}%s ${CYAN}%s${MAGENTA}%s${NC}\n" "Loading profile" "${profile_name}" "..."

	for file_type in "aliases" "plugins" "completions"; do
		_gaudi-shell-disable "$file_type" "all"
	done

	while IFS= read -r line || [[ -n "$line" ]]; do
		[[ -z "$line" ]] && continue
		local _type="${line%% *}" _component="${line#* }"
		_gaudi-shell-enable "$(_gaudi-shell-pluralize-component "$_type")" "$_component"
	done <"${profile_file}"

	printf "${GREEN}%s ${CYAN}%s${GREEN}%s${NC}\n" "Profile" "${profile_name}" " loaded"
}

_gaudi-shell-profile-list() {
	local profile_dir="${GAUDI_SHELL}/profiles"
	if [[ ! -d "$profile_dir" ]] || [[ -z "$(command ls -A "${profile_dir}"/*.gaudi-shell 2>/dev/null)" ]]; then
		printf "${CYAN}%s${NC}\n" "No profiles found"
		return 0
	fi
	printf "${GREEN}%s${NC}\n" "Available profiles:"
	for _profile in "${profile_dir}"/*.gaudi-shell; do
		local _name _count
		_name="$(basename "$_profile" .gaudi-shell)"
		_count=$(wc -l <"$_profile" | tr -d ' ')
		printf "  ${CYAN}%s${NC} (%s component(s))\n" "$_name" "$_count"
	done
}

_gaudi-shell-profile-rm() {
	local profile_name="$1"
	[[ -z "$profile_name" ]] && printf "${RED}%s${NC}\n" "Please provide a profile name" && return 1
	[[ "$profile_name" == "default" ]] && printf "${RED}%s${NC}\n" "Cannot remove 'default' profile" && return 1

	local profile_file="${GAUDI_SHELL}/profiles/${profile_name}.gaudi-shell"
	[[ ! -f "$profile_file" ]] && printf "${RED}%s ${CYAN}%s${RED}%s${NC}\n" "Profile" "${profile_name}" " not found" && return 1
	rm "${profile_file}"
	printf "${GREEN}%s ${CYAN}%s${GREEN}%s${NC}\n" "Profile" "${profile_name}" " removed"
}

_gaudi-shell-profile() {
	local action="$1"
	shift
	case "$action" in
	save) _gaudi-shell-profile-save "$@" ;;
	load) _gaudi-shell-profile-load "$@" ;;
	list) _gaudi-shell-profile-list ;;
	rm) _gaudi-shell-profile-rm "$@" ;;
	*)
		printf "%s\n" "Usage: gaudi profile [save|load|list|rm] [name]"
		return 1
		;;
	esac
}
