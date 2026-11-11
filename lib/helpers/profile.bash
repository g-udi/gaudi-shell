#!/usr/bin/env bash
# shellcheck shell=bash

# Profile written by "gshell backup" and read by "gshell restore".
GAUDI_SHELL_BACKUP_PROFILE="backup"

# Print the path of the profile named $1.
_gaudi-shell-profile-file() {
	printf '%s\n' "${GAUDI_SHELL}/profiles/${1}.gaudi-shell"
}

# Print the enabled components, one "<type> <name>" per line (the profile format).
_gaudi-shell-enabled-entries() {
	local _file _component
	for _file in "${GAUDI_SHELL}"/components/enabled/*.bash; do
		[[ ! -e "$_file" ]] && continue
		_component="${_file##*"$GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR"}"
		_component="${_component%.bash}"
		printf '%s %s\n' "$(_gaudi-shell-singularize-component "${_component##*.}")" "${_component%%.*}"
	done
}

# Read one profile line ($1) into _profile_type and _profile_component.
# Accepts "<type> <name>" and the "gshell enable <type> <name>" form of old
# backup files. Returns non-zero for anything else.
_gaudi-shell-profile-parse() {
	local _line="$1"
	case "$_line" in
	"gshell enable "* | "gaudi enable "*) _line="${_line#* enable }" ;;
	esac
	_profile_type="${_line%%[[:space:]]*}"
	_profile_component="${_line#"$_profile_type"}"
	_profile_component="${_profile_component#"${_profile_component%%[![:space:]]*}"}"

	case "$_profile_type" in
	alias | plugin | completion) ;;
	*) return 1 ;;
	esac
	case "$_profile_component" in
	"" | *[!a-zA-Z0-9_-]*) return 1 ;;
	esac
	return 0
}

# Check every line of the profile file $1: it must be well formed and name a
# component that exists. Prints what is wrong; returns non-zero if anything is.
_gaudi-shell-profile-check() {
	local _line _line_num=0 _errors=0 _profile_type _profile_component _types
	while IFS= read -r _line || [[ -n "$_line" ]]; do
		_line_num=$((_line_num + 1))
		[[ -z "$_line" ]] && continue
		if ! _gaudi-shell-profile-parse "$_line"; then
			printf "${RED}%s${NC} %s: %s\n" "Invalid entry" "line ${_line_num}" "${_line}"
			_errors=$((_errors + 1))
			continue
		fi
		_types="$(_gaudi-shell-pluralize-component "$_profile_type")"
		if [[ ! -e "${GAUDI_SHELL}/components/${_types}/${_profile_component}.${_types}.bash" ]]; then
			printf "${RED}%s${NC} %s: %s\n" "Unknown ${_profile_type}" "line ${_line_num}" "${_profile_component}"
			_errors=$((_errors + 1))
		fi
	done <"$1"
	[[ $_errors -eq 0 ]]
}

# Enable every component listed in the profile file $1. Lines that are not
# well formed are skipped with a warning. Returns non-zero if a component
# could not be enabled.
_gaudi-shell-profile-apply() {
	local _line _profile_type _profile_component _rc=0
	while IFS= read -r _line || [[ -n "$_line" ]]; do
		[[ -z "$_line" ]] && continue
		if _gaudi-shell-profile-parse "$_line"; then
			_gaudi-shell-enable "$_profile_type" "$_profile_component" || _rc=1
		else
			_log_warning "Skipping invalid entry: $_line"
		fi
	done <"$1"
	return "$_rc"
}

_gaudi-shell-profile-save() {
	local profile_name="$1"
	[[ -z "$profile_name" ]] && printf "${RED}%s${NC}\n" "Please provide a profile name" && return 1
	if [[ "$profile_name" == "$GAUDI_SHELL_BACKUP_PROFILE" ]]; then
		printf "${RED}%s${NC}\n" "'${profile_name}' is the profile written by 'gshell backup'; pick another name"
		return 1
	fi

	local profile_file _count
	profile_file="$(_gaudi-shell-profile-file "$profile_name")"
	mkdir -p "${profile_file%/*}"

	if [[ -f "$profile_file" ]]; then
		_read_input "Profile '${profile_name}' already exists. Overwrite? [yY/nN]"
		[[ ! $REPLY =~ ^[yY]$ ]] && printf "${CYAN}%s${NC}\n" "Profile save cancelled" && return 0
	fi

	_gaudi-shell-enabled-entries >"${profile_file}" || return 1
	_count=$(wc -l <"$profile_file" | tr -d ' ')

	printf "${GREEN}%s${NC} %s ${CYAN}%s${NC}\n" "Profile saved:" "${_count} component(s) to" "${profile_name}"
}

_gaudi-shell-profile-load() {
	local profile_name="$1"
	[[ -z "$profile_name" ]] && printf "${RED}%s${NC}\n" "Please provide a profile name" && return 1

	local profile_file file_type
	profile_file="$(_gaudi-shell-profile-file "$profile_name")"
	[[ ! -f "$profile_file" ]] && printf "${RED}%s ${CYAN}%s${RED}%s${NC}\n" "Profile" "${profile_name}" " not found" && return 1

	# Checked before anything is disabled: a profile with a typo or a component
	# that no longer exists must not leave the shell with half its components.
	if ! _gaudi-shell-profile-check "$profile_file"; then
		printf "${RED}%s${NC}\n" "Profile validation failed, nothing was changed"
		return 1
	fi

	printf "${MAGENTA}%s ${CYAN}%s${MAGENTA}%s${NC}\n" "Loading profile" "${profile_name}" "..."

	for file_type in "aliases" "plugins" "completions"; do
		_gaudi-shell-disable "$file_type" "all"
	done

	if ! _gaudi-shell-profile-apply "$profile_file"; then
		printf "${RED}%s ${CYAN}%s${RED}%s${NC}\n" "Profile" "${profile_name}" " was only partly loaded"
		return 1
	fi

	printf "${GREEN}%s ${CYAN}%s${GREEN}%s${NC}\n" "Profile" "${profile_name}" " loaded"
}

_gaudi-shell-profile-list() {
	local profile_dir="${GAUDI_SHELL}/profiles"
	local _profile _name _count _found=""
	for _profile in "${profile_dir}"/*.gaudi-shell; do
		[[ -f "$_profile" ]] || continue
		[[ -z "$_found" ]] && printf "${GREEN}%s${NC}\n" "Available profiles:" && _found=1
		_name="${_profile##*/}"
		_name="${_name%.gaudi-shell}"
		_count=$(wc -l <"$_profile" | tr -d ' ')
		printf "  ${CYAN}%s${NC} (%s component(s))\n" "$_name" "$_count"
	done
	[[ -n "$_found" ]] || printf "${CYAN}%s${NC}\n" "No profiles found"
}

_gaudi-shell-profile-rm() {
	local profile_name="$1"
	[[ -z "$profile_name" ]] && printf "${RED}%s${NC}\n" "Please provide a profile name" && return 1
	[[ "$profile_name" == "default" ]] && printf "${RED}%s${NC}\n" "Cannot remove 'default' profile" && return 1

	local profile_file
	profile_file="$(_gaudi-shell-profile-file "$profile_name")"
	[[ ! -f "$profile_file" ]] && printf "${RED}%s ${CYAN}%s${RED}%s${NC}\n" "Profile" "${profile_name}" " not found" && return 1
	rm "${profile_file}"
	printf "${GREEN}%s ${CYAN}%s${GREEN}%s${NC}\n" "Profile" "${profile_name}" " removed"
}

_gaudi-shell-profile() {
	local action="${1:-}"
	[[ $# -gt 0 ]] && shift
	case "$action" in
	save) _gaudi-shell-profile-save "$@" ;;
	load) _gaudi-shell-profile-load "$@" ;;
	list) _gaudi-shell-profile-list ;;
	rm) _gaudi-shell-profile-rm "$@" ;;
	*)
		printf "%s\n" "Usage: gshell profile [save|load|list|rm] [name]"
		return 1
		;;
	esac
}
