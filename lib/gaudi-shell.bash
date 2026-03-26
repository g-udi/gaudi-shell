#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC1090,SC2034

export GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR="___"

_gaudi-shell-version() {
	cd "${GAUDI_SHELL}" || return
	local GAUDI_SHELL_GIT_REMOTE GAUDI_SHELL_GIT_URL GAUDI_SHELL_GIT_VERSION_INFO GAUDI_SHELL_GIT_SHA GAUDI_SHELL_GIT_TAG

	GAUDI_SHELL_GIT_REMOTE=$(git remote get-url "${GAUDI_SHELL_REMOTE:-origin}" 2>/dev/null)
	GAUDI_SHELL_GIT_URL=${GAUDI_SHELL_GIT_REMOTE%.git}
	GAUDI_SHELL_GIT_TAG="$(git describe --tags --abbrev=0 2>/dev/null)"
	GAUDI_SHELL_GIT_VERSION_INFO="$(git log --pretty=format:'%h on %aI' -n 1)"
	GAUDI_SHELL_GIT_SHA=${GAUDI_SHELL_GIT_VERSION_INFO%% *}

	echo "gaudi-shell (${GAUDI_SHELL_CURRENT})"
	[[ -n "$GAUDI_SHELL_GIT_TAG" ]] && echo -e "  Version: ${CYAN}$GAUDI_SHELL_GIT_TAG${NC}"
	echo -e "  SHA: ${GREEN}$GAUDI_SHELL_GIT_VERSION_INFO${NC}"
	[[ -n "$GAUDI_SHELL_GIT_URL" ]] && echo -e "  ${MAGENTA}$GAUDI_SHELL_GIT_URL/commit/$GAUDI_SHELL_GIT_SHA${NC}"
	cd - &>/dev/null || return
}

_gaudi-shell-reload() {
	if [[ -n $GAUDI_TEST_RUNNER ]]; then
		return 0
	fi
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

_gaudi-shell-restart() {
	_gaudi-shell-component-cache-clean
	exec "${GAUDI_SHELL_CURRENT}" --login
}

_gaudi-shell-help() {
	! __check-function-parameters "$1" && echo "Usage: gaudi <command> [args]. Run 'gaudi help' for details." && return 0
	local type component
	type="$(_gaudi-shell-pluralize-component "$1")"
	_command_exists _help-"${type}" && _help-"${type}" "$2"
}

_gaudi-shell-show() {
	if [[ -n "$1" ]]; then
		_gaudi-shell-describe "$1" "$2" || return $?
		_gaudi-shell-show-usage "$1"
		return 0
	else
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
	printf "gaudi enable %s%s%s  <%s name> [%s name]... -or- \$ gaudi enable %s%s%s all\n\n" "$_green" "$type" "$_nc" "$type" "$type" "$_green" "$type_plural" "$_nc"
	printf "to disable %s, do:\n" "$type"
	printf "gaudi disable %s%s%s <%s name> [%s name]... -or- \$ gaudi disable %s%s%s all\n" "$_green" "$type" "$_nc" "$type" "$type" "$_green" "$type_plural" "$_nc"
}

_gaudi-shell-backup() {
	mkdir -p "${GAUDI_SHELL}/tmp"
	echo -n "" > "${GAUDI_SHELL}/tmp/enabled.gaudi-shell.backup"
	for _file in "${GAUDI_SHELL}"/components/enabled/*.bash; do
		[[ ! -e "$_file" ]] && continue
		local _component _type
		_component="${_file##*"$GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR"}"
		_component="${_component%.bash}"
		_type=$(_gaudi-shell-singularize-component "${_component##*.}")
		_component=${_component%%.*}
		echo "Backing up $_type: ${_component}"
		printf "%s\n" "gaudi enable ${_type} ${_component}" >> "${GAUDI_SHELL}/tmp/enabled.gaudi-shell.backup"
	done
}

_gaudi-shell-restore() {
	! [[ -f "${GAUDI_SHELL}/tmp/enabled.gaudi-shell.backup" ]] && echo -e "${RED}No valid backup file found :(${NC}" && return
	while IFS= read -r line; do
		if [[ "$line" =~ ^gaudi\ enable\ (alias|plugin|completion)\ [a-zA-Z0-9_-]+$ ]]; then
			$line
		else
			_log_warning "Skipping invalid backup entry: $line"
		fi
	done < "${GAUDI_SHELL}/tmp/enabled.gaudi-shell.backup"
}

gaudi() {
	local verb=${1:-}
	shift 2>/dev/null || true
	local component=${1:-}
	shift 2>/dev/null || true
	local func

	case $verb in
		show) func=_gaudi-shell-show ;;
		enable) func=_gaudi-shell-enable ;;
		disable) func=_gaudi-shell-disable ;;
		help) _gaudi-shell-help "$component" "$@"; return ;;
		doctor) func=_gaudi-shell-doctor ;;
		update) _gaudi-shell-update "$component" "$@"; return ;;
		version) func=_gaudi-shell-version ;;
		backup) func=_gaudi-shell-backup ;;
		restore) func=_gaudi-shell-restore ;;
		profile) _gaudi-shell-profile "$component" "$@"; return ;;
		reload) func=_gaudi-shell-reload ;;
		restart) func=_gaudi-shell-restart ;;
		search) _gaudi-shell-search "$component" "$@"; return ;;
		*) echo "Usage: gaudi <command> [args]. Run 'gaudi help' for details."; return ;;
	esac

	if [[ "$verb" == "enable" || "$verb" == "disable" ]] && [[ ${#@} != 0 ]]; then
		for arg in "$@"; do
			$func "$(_gaudi-shell-pluralize-component "$component")" "$arg"
		done
	else
		$func "$(_gaudi-shell-pluralize-component "$component")" "$@"
	fi
}

# Short alias
alias g='gaudi'
