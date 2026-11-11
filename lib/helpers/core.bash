#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2001

# Cache grep path at startup
: "${GAUDI_SHELL_GREP:=$(command -v egrep 2>/dev/null || command -v grep 2>/dev/null || echo '/usr/bin/grep')}"
export GAUDI_SHELL_GREP

# Print the enabled link of a component file (e.g. git.aliases.bash).
# Returns non-zero when there is none; a dangling link does not count.
_gaudi-shell-enabled-link() {
	local link
	for link in "${GAUDI_SHELL}"/components/enabled/[0-9]*"${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}${1}"; do
		[[ -e "$link" ]] || continue
		printf '%s\n' "$link"
		return 0
	done
	return 1
}

# Print the description of each component file given, one per line and in the
# same order (an empty line when a file has none): the text of its first
#   about-<type> 'description'
# line, commented out or not. One awk process for the whole list.
_gaudi-shell-component-descriptions() {
	# The quote characters are passed in, so the program needs no escapes.
	awk -v q="'" '
		BEGIN {
			quotes = "[" q "\"]*"
			prefix = "^[# ]*about-[a-z]* " quotes
			line = prefix "[^" q "\"]*" quotes "$"
		}
		FNR == 1 { found = 0 }
		!found && $0 ~ line {
			text = $0
			sub(prefix, "", text)
			sub(quotes "$", "", text)
			description[FILENAME] = text
			found = 1
		}
		END { for (i = 1; i < ARGC; i++) print description[ARGV[i]] }
	' "$@" 2>/dev/null
}

_gaudi-shell-describe() {
	__check-function-parameters "$1" || return 1
	case "${2:-all}" in
	enabled | all) ;;
	*)
		echo "unsupported describe mode"
		return 1
		;;
	esac

	local component component_type mode file
	component=$(_gaudi-shell-pluralize-component "$1")
	component_type="$(_gaudi-shell-singularize-component "$component")"
	mode=${2:-"all"}

	local _cap_type
	case "$component_type" in
	alias) _cap_type="Alias" ;;
	plugin) _cap_type="Plugin" ;;
	completion) _cap_type="Completion" ;;
	esac
	printf "\n%-20s%-10s%s\n" "$_cap_type" 'Enabled?' '  Description'
	printf "%*s\n" "${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}" '' | tr ' ' -

	file=$(_gaudi-shell-component-cache-add "$component-enabled")
	[[ "$mode" = "all" ]] && file=${file/-enabled/}

	if [[ ! -s "${file}" ]]; then
		rm -f "${file}" 2>/dev/null
		local __file enabled_file component_name about_text
		local -a __files
		__files=()
		while IFS= read -r __file; do
			[[ -n "$__file" ]] && __files+=("$__file")
		done < <(_gaudi-shell-component-files "$component")
		[[ ${#__files[@]} -gt 0 ]] || return 0

		for __file in "${__files[@]}"; do
			IFS= read -r about_text <&3
			enabled_file="${__file##*/}"
			component_name="${enabled_file%%.*}"

			if _gaudi-shell-enabled-link "$enabled_file" >/dev/null; then
				printf "%-20s${GREEN}%-10s${NC}%s\n" "$component_name" "  ◉" "    $about_text"
			elif [[ "$mode" = "all" ]]; then
				printf "%-20s${RED}%-10s${NC}%s\n" "$component_name" "  ◯" "    $about_text"
			fi
		done 3< <(_gaudi-shell-component-descriptions "${__files[@]}") | tee -a "${file}"
	else
		cat "${file}"
	fi
}
