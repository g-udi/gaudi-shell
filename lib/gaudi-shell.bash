#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC1090,SC2034

export GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR="___"

_gaudi-shell-version() {
	# git -C, not cd: the current directory, OLDPWD and directory hooks are left alone.
	local GAUDI_SHELL_GIT_REMOTE GAUDI_SHELL_GIT_URL GAUDI_SHELL_GIT_VERSION_INFO GAUDI_SHELL_GIT_SHA GAUDI_SHELL_GIT_TAG

	GAUDI_SHELL_GIT_REMOTE=$(git -C "${GAUDI_SHELL}" remote get-url "${GAUDI_SHELL_REMOTE:-origin}" 2>/dev/null)
	GAUDI_SHELL_GIT_URL=${GAUDI_SHELL_GIT_REMOTE%.git}
	GAUDI_SHELL_GIT_TAG="$(git -C "${GAUDI_SHELL}" describe --tags --abbrev=0 2>/dev/null)"
	GAUDI_SHELL_GIT_VERSION_INFO="$(git -C "${GAUDI_SHELL}" log --pretty=format:'%h on %aI' -n 1 2>/dev/null)"
	GAUDI_SHELL_GIT_SHA=${GAUDI_SHELL_GIT_VERSION_INFO%% *}

	echo "gaudi-shell (${GAUDI_SHELL_CURRENT})"
	[[ -n "$GAUDI_SHELL_GIT_TAG" ]] && echo -e "  Version: ${CYAN}$GAUDI_SHELL_GIT_TAG${NC}"
	echo -e "  SHA: ${GREEN}$GAUDI_SHELL_GIT_VERSION_INFO${NC}"
	[[ -n "$GAUDI_SHELL_GIT_URL" ]] && echo -e "  ${MAGENTA}$GAUDI_SHELL_GIT_URL/commit/$GAUDI_SHELL_GIT_SHA${NC}"
	return 0
}

_gaudi-shell-reload() {
	_gaudi-shell-component-cache-clean
	local profile="${HOME?}/${GAUDI_SHELL_PROFILE}"
	if [[ -f "$profile" ]]; then
		source "$profile"
		echo "gaudi-shell reloaded from $profile"
	else
		echo "Profile not found: $profile"
		return 1
	fi
}

# Called after a component was enabled or disabled. Reloads the profile when
# GAUDI_SHELL_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE is set: at once, or, inside
# a gshell command, once when that command is done (see gshell below).
_gaudi-shell-reload-after-change() {
	[[ -n "${GAUDI_SHELL_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE:-}" ]] || return 0
	if [[ -n "${_gaudi_shell_reload_deferred:-}" ]]; then
		_gaudi_shell_reload_wanted=1
	else
		_gaudi-shell-reload
	fi
}

_gaudi-shell-restart() {
	_gaudi-shell-component-cache-clean
	exec "${GAUDI_SHELL_CURRENT}" --login
}

# The one table of gshell commands. Usage, the dispatcher and both shell
# completions read it, so a command is added or renamed here only.
# One line per command, fields separated by ";":
#   name ; arguments (for usage) ; description ; words completed as first argument ; words completed as second argument
# The handler of a command is the function _gaudi-shell-<name>.
_gaudi-shell-verbs() {
	printf '%s\n' \
		"show;[aliases|plugins|completions] [enabled];list components (no type: everything enabled);aliases plugins completions;enabled" \
		"enable;<alias|plugin|completion> <name>...|all;enable components;alias plugin completion;" \
		"disable;<alias|plugin|completion> <name>...|all;disable components;alias plugin completion;" \
		"search;<term>... [--enable|--disable];find components ('gshell search --help' for details);--enable --disable --plugin --alias --completion --no-color --refresh --help;--enable --disable --plugin --alias --completion --no-color --refresh --help" \
		"help;[aliases|plugins|completions];this usage, or what the enabled components of a type provide;aliases plugins completions;" \
		"profile;<save|load|list|rm> [name];save and switch sets of enabled components;save load list rm;" \
		"backup;;record the enabled components;;" \
		"restore;;re-enable the components recorded by 'backup';;" \
		"update;[stable|dev] [--silent];update to the latest tag (stable, default) or the development branch;stable dev --silent;--silent" \
		"migrate;;fetch the shared components if missing and repair enabled links left by an older layout;;" \
		"doctor;[errors|warnings|all];reload with logging at the given level;errors warnings all;" \
		"reload;;re-source your shell profile;;" \
		"restart;;re-exec the shell;;" \
		"version;;show version, git SHA and shell;;"
}

# Print field number $2 (1 to 5, see _gaudi-shell-verbs) of the command $1.
# Returns non-zero when there is no such command.
_gaudi-shell-verb-field() {
	local _entry _field _n
	while IFS= read -r _entry; do
		[[ "${_entry%%;*}" == "$1" ]] || continue
		_n=1
		while [[ $_n -lt $2 ]]; do
			_entry="${_entry#*;}"
			_n=$((_n + 1))
		done
		printf '%s\n' "${_entry%%;*}"
		return 0
	done < <(_gaudi-shell-verbs)
	return 1
}

# Print the command names, separated by spaces.
_gaudi-shell-verb-names() {
	local _entry _names=""
	while IFS= read -r _entry; do
		_names="${_names:+$_names }${_entry%%;*}"
	done < <(_gaudi-shell-verbs)
	printf '%s\n' "$_names"
}

_gaudi-shell-usage() {
	local _entry _name _arguments
	printf '%s\n\n%s\n' "Usage: gshell <command> [args]  (short alias: g)" "Commands:"
	while IFS= read -r _entry; do
		_name="${_entry%%;*}"
		_entry="${_entry#*;}"
		_arguments="${_entry%%;*}"
		_entry="${_entry#*;}"
		printf '  %-51s%s\n' "${_name}${_arguments:+ $_arguments}" "${_entry%%;*}"
	done < <(_gaudi-shell-verbs)
}

_gaudi-shell-help() {
	! __check-function-parameters "$1" && _gaudi-shell-usage && return 0
	local type
	type="$(_gaudi-shell-pluralize-component "$1")"
	_command_exists _help-"${type}" && _help-"${type}" "$2"
}

_gaudi-shell-show() {
	if [[ -n "$1" ]]; then
		_gaudi-shell-describe "$1" "$2" || return $?
		_gaudi-shell-show-usage "$1"
		return 0
	else
		local file_type
		for file_type in "aliases" "plugins" "completions"; do
			_gaudi-shell-describe "$file_type" "enabled" || return $?
		done
	fi
}

_gaudi-shell-show-usage() {
	local type type_plural
	__check-function-parameters "$1" || return 1
	type="$(_gaudi-shell-singularize-component "$1")"
	type_plural="$(_gaudi-shell-pluralize-component "$1")"

	local _green="${GREEN:-}" _nc="${NC:-}"
	printf "\ngaudi-shell allows you to easily enable/disable components:\n\n"
	printf "to enable %s, do:\n" "$type"
	printf "gshell enable %s%s%s  <%s name> [%s name]... -or- \$ gshell enable %s%s%s all\n\n" "$_green" "$type" "$_nc" "$type" "$type" "$_green" "$type_plural" "$_nc"
	printf "to disable %s, do:\n" "$type"
	printf "gshell disable %s%s%s <%s name> [%s name]... -or- \$ gshell disable %s%s%s all\n" "$_green" "$type" "$_nc" "$type" "$type" "$_green" "$type_plural" "$_nc"
}

# backup and restore are a profile under a reserved name (see
# lib/helpers/profile.bash): "backup" saves it, "restore" enables what it
# lists without disabling anything else.
_gaudi-shell-backup() {
	local _backup _line
	_backup="$(_gaudi-shell-profile-file "$GAUDI_SHELL_BACKUP_PROFILE")"
	mkdir -p "${_backup%/*}" || return 1
	_gaudi-shell-enabled-entries >"$_backup" || return 1

	while IFS= read -r _line; do
		echo "Backing up ${_line%% *}: ${_line#* }"
	done <"$_backup"

	# The backup written before backups became a profile is now out of date.
	rm -f "${GAUDI_SHELL}/tmp/enabled.gaudi-shell.backup"
}

_gaudi-shell-restore() {
	local _backup
	_backup="$(_gaudi-shell-profile-file "$GAUDI_SHELL_BACKUP_PROFILE")"
	# Older versions kept the backup here, as "gshell enable <type> <name>" lines.
	[[ -f "$_backup" ]] || _backup="${GAUDI_SHELL}/tmp/enabled.gaudi-shell.backup"

	if [[ ! -f "$_backup" ]]; then
		echo -e "${RED}No valid backup file found :(${NC}"
		return 1
	fi
	_gaudi-shell-profile-apply "$_backup"
}

gshell() {
	local verb="${1:-}"
	[[ $# -gt 0 ]] && shift

	if [[ -z "$verb" ]] || ! _gaudi-shell-verb-field "$verb" 1 >/dev/null; then
		[[ -n "$verb" ]] && echo "gshell: unknown command '$verb'" >&2
		echo "Usage: gshell <command> [args]. Run 'gshell help' for details."
		return 1
	fi

	# An automatic reload (see _gaudi-shell-reload-after-change) happens once,
	# here, however many components the command enabled or disabled.
	local _gaudi_shell_reload_deferred=1 _gaudi_shell_reload_wanted="" rc=0

	case "$verb" in
	enable | disable)
		local type="${1:-}" name
		[[ $# -gt 0 ]] && shift
		if [[ $# -eq 0 ]]; then
			"_gaudi-shell-${verb}" "$type" || rc=$?
		else
			for name in "$@"; do
				"_gaudi-shell-${verb}" "$type" "$name" || rc=$?
			done
		fi
		;;
	*)
		"_gaudi-shell-${verb}" "$@" || rc=$?
		;;
	esac

	if [[ -n "$_gaudi_shell_reload_wanted" ]]; then
		_gaudi_shell_reload_deferred=""
		_gaudi-shell-reload
	fi
	return "$rc"
}

# Short alias
alias g='gshell'
