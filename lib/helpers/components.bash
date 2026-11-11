#!/usr/bin/env bash
# shellcheck shell=bash

# There are exactly three component types, so both name helpers are a lookup.
# Anything else is passed through the way the old generic code did ("foo"
# becomes "foos"), which callers then reject as an unknown type.
__check-function-parameters() {
	case "$1" in
	alias | aliases | plugin | plugins | completion | completions) return 0 ;;
	esac
	return 1
}

_gaudi-shell-pluralize-component() {
	case "$1" in
	"") return 1 ;;
	alias | aliases) printf "%s" "aliases" ;;
	plugin | plugins) printf "%s" "plugins" ;;
	completion | completions) printf "%s" "completions" ;;
	*s) printf "%s" "$1" ;;
	*) printf "%s" "${1}s" ;;
	esac
}

_gaudi-shell-singularize-component() {
	case "$1" in
	"") return 1 ;;
	alias | aliases) printf "%s" "alias" ;;
	plugin | plugins) printf "%s" "plugin" ;;
	completion | completions) printf "%s" "completion" ;;
	*s) printf "%s" "${1%s}" ;;
	*) printf "%s" "$1" ;;
	esac
}

_gaudi-shell-component-help() {
	__check-function-parameters "$1" || return 1
	local type component help
	type=$(_gaudi-shell-pluralize-component "${1}")
	component="$2"
	help=$(_gaudi-shell-describe "$type" | tail -n +4)
	if [[ -n $component ]]; then
		printf "%s" "$help" | grep "${component}" && return 0
		return 1
	fi
	printf "%s" "${help}"
}

_gaudi-shell-component-list() {
	__check-function-parameters "$1" || return 1
	_gaudi-shell-component-help "$1" | awk '{print $1}' | uniq | sort | tr '\n' ' '
}

_gaudi-shell-component-list-matching() {
	__check-function-parameters "$1" || return 1
	if [[ -n "$1" ]] && [[ -n "$2" ]]; then
		local match
		match=$(_gaudi-shell-component-help "$1" | $GAUDI_SHELL_GREP -E -- "$2" | awk '{print $1}' | uniq | sort | tr '\n' ' ')
		[[ -n "$match" ]] && echo "$match" && return 0
	fi
	return 1
}

_gaudi-shell-component-list-enabled() {
	__check-function-parameters "$1" || return 1
	_gaudi-shell-component-help "${1}" | $GAUDI_SHELL_GREP -E '◉' | awk '{print $1}' | uniq | sort | tr '\n' ' '
}

_gaudi-shell-component-item-is-enabled() {
	__check-function-parameters "$1" || return 1
	if [[ -n "$1" ]] && [[ -n "$2" ]]; then
		_gaudi-shell-component-list-enabled "$1" | tr ' ' '\n' | $GAUDI_SHELL_GREP -E -q -- "^${2}$"
	else
		return 1
	fi
}

# Where component files live
# --------------------------
# This is the one place that knows it. Everything else asks
# _gaudi-shell-component-file (one component) or _gaudi-shell-component-files
# (all components of a type) and never spells out a path itself.
#
#   components/host/<name>.<type>.bash        this framework's own files, tracked here
#   components/<type>/lib/<name>.<type>.bash  shared files: components/aliases,
#                                             components/completions and components/plugins
#                                             are git submodules of the shared repositories
#
# components/host is looked at first, so a host file wins over a shared file
# of the same name. An enabled component is a relative link in
# components/enabled to one of those two places (_gaudi-shell-component-link-target).

# The shared repositories also carry the own files of the other frameworks
# that use them, named after that framework (gaudi-bash.aliases.bash, ...).
# Those are never listed, enabled, searched or completed here. One name per
# word; this framework's own name is GAUDI_HOST_NAME and is not in the list.
GAUDI_SHELL_FOREIGN_HOSTS="gaudi-bash"

# True when the component name $1 is the own file of another framework.
_gaudi-shell-component-is-foreign() {
	[[ "$1" != "${GAUDI_HOST_NAME:-gaudi-shell}" ]] || return 1
	case " ${GAUDI_SHELL_FOREIGN_HOSTS} " in
	*" $1 "*) return 0 ;;
	esac
	return 1
}

# Print the path of the component named $2 of type $1 (alias, aliases, ...).
# Returns non-zero when there is no such component.
_gaudi-shell-component-file() {
	__check-function-parameters "$1" || return 1
	[[ -n "${2:-}" ]] || return 1
	_gaudi-shell-component-is-foreign "$2" && return 1
	local _cf_type _cf_file
	_cf_type="$(_gaudi-shell-pluralize-component "$1")"
	for _cf_file in \
		"${GAUDI_SHELL}/components/host/${2}.${_cf_type}.bash" \
		"${GAUDI_SHELL}/components/${_cf_type}/lib/${2}.${_cf_type}.bash"; do
		if [[ -f "$_cf_file" ]]; then
			printf '%s\n' "$_cf_file"
			return 0
		fi
	done
	return 1
}

# Print the path of every component of type $1, one per line, sorted by
# component name.
_gaudi-shell-component-files() {
	__check-function-parameters "$1" || return 1
	# zsh: leave a pattern without matches as it is instead of raising an error
	[[ -n "${ZSH_VERSION:-}" ]] && setopt local_options no_nomatch
	local _cf_type _cf_file _cf_name
	_cf_type="$(_gaudi-shell-pluralize-component "$1")"
	{
		for _cf_file in "${GAUDI_SHELL}/components/host/"*."${_cf_type}.bash"; do
			[[ -f "$_cf_file" ]] && printf '%s\n' "$_cf_file"
		done
		for _cf_file in "${GAUDI_SHELL}/components/${_cf_type}/lib/"*."${_cf_type}.bash"; do
			[[ -f "$_cf_file" ]] || continue
			_cf_name="${_cf_file##*/}"
			_cf_name="${_cf_name%."${_cf_type}".bash}"
			_gaudi-shell-component-is-foreign "$_cf_name" && continue
			# A host file of the same name wins.
			[[ -f "${GAUDI_SHELL}/components/host/${_cf_name}.${_cf_type}.bash" ]] && continue
			printf '%s\n' "$_cf_file"
		done
		# Sorted on the file name, which is put in front for the sort only.
	} | awk -F/ '{ print $NF "/" $0 }' | sort | cut -d/ -f2-
}

# Print the target of the enabled link of the component file $1 (a path
# printed by the two functions above): relative to components/enabled, so the
# links keep working when the install directory is moved or renamed.
_gaudi-shell-component-link-target() {
	printf '%s\n' "../${1#"${GAUDI_SHELL}/components/"}"
}

# The folders that are git submodules of the shared component repositories.
GAUDI_SHELL_COMPONENT_SUBMODULES=(components/aliases components/completions components/plugins)

# True when the shared components are there: every submodule of the install
# directory $1 (default: GAUDI_SHELL) has been checked out.
_gaudi-shell-component-submodules-present() {
	local _cs_dir="${1:-${GAUDI_SHELL}}" _cs_path
	for _cs_path in "${GAUDI_SHELL_COMPONENT_SUBMODULES[@]}"; do
		[[ -d "${_cs_dir}/${_cs_path}/lib" ]] || return 1
	done
	return 0
}

# Print the command that fetches the shared components by hand.
_gaudi-shell-component-submodules-command() {
	printf '%s\n' "git -C \"${1:-${GAUDI_SHELL}}\" submodule update --init ${GAUDI_SHELL_COMPONENT_SUBMODULES[*]}"
}

# Check out the shared components of the install directory $1 (default:
# GAUDI_SHELL) at the commits this version of the framework pins. Only these
# three submodules: bin/bats-* are test tools for developers. Any further
# arguments are passed to "git submodule update" (install.sh adds --depth=1).
# Used by install.sh, by "gshell update" and by "gshell migrate".
_gaudi-shell-update-component-submodules() {
	local _cs_dir="${1:-${GAUDI_SHELL}}"
	[[ $# -gt 0 ]] && shift
	git -C "$_cs_dir" submodule update --init "$@" "${GAUDI_SHELL_COMPONENT_SUBMODULES[@]}"
}

# Rewrite the enabled links left behind by an older layout: a link whose
# target is gone (components/<type>/<file> before the shared components became
# submodules, or an absolute path into an install directory that has moved)
# while the component still exists is pointed at where the component is now.
# The link keeps its name, so its load priority is unchanged. Links that work,
# and links to components that no longer exist, are left alone, so running
# this again changes nothing. Prints one line per link it rewrites.
_gaudi-shell-migrate-enabled-links() {
	[[ -n "${ZSH_VERSION:-}" ]] && setopt local_options no_nomatch
	local _ml_separator="${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR:-___}"
	local _ml_link _ml_file _ml_type _ml_name _ml_path _ml_target _ml_count=0
	for _ml_link in "${GAUDI_SHELL}"/components/enabled/*.bash; do
		[[ -L "$_ml_link" && ! -e "$_ml_link" ]] || continue
		_ml_file="${_ml_link##*/}"
		_ml_file="${_ml_file#*"${_ml_separator}"}"
		_ml_name="${_ml_file%.bash}"
		_ml_type="${_ml_name##*.}"
		_ml_name="${_ml_name%.*}"
		_ml_path="$(_gaudi-shell-component-file "$_ml_type" "$_ml_name")" || continue
		_ml_target="$(_gaudi-shell-component-link-target "$_ml_path")"
		rm -f "$_ml_link"
		ln -s "$_ml_target" "$_ml_link" || continue
		printf '%s\n' "migrated ${_ml_link##*/} -> ${_ml_target}"
		_ml_count=$((_ml_count + 1))
	done
	if [[ $_ml_count -gt 0 ]] && type _gaudi-shell-component-cache-clean >/dev/null 2>&1; then
		_gaudi-shell-component-cache-clean
	fi
	return 0
}

# "gshell migrate": bring an install made before the shared components became
# submodules up to date. Fetches the shared components when they are missing,
# then repairs the enabled links. Safe to run at any time.
_gaudi-shell-migrate() {
	if ! _gaudi-shell-component-submodules-present; then
		echo "Fetching the shared components..."
		if ! _gaudi-shell-update-component-submodules "${GAUDI_SHELL}"; then
			echo "Could not fetch the shared components. Check the network, then run: $(_gaudi-shell-component-submodules-command)" >&2
			return 1
		fi
	fi
	local _migrated
	_migrated="$(_gaudi-shell-migrate-enabled-links)"
	if [[ -n "$_migrated" ]]; then
		printf '%s\n' "$_migrated"
		echo "Run 'gshell reload' to load the migrated components."
	else
		echo "Nothing to migrate."
	fi
}
