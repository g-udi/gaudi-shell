#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2001

# Cache grep path at startup
: "${GAUDI_SHELL_GREP:=$(type -P egrep 2>/dev/null || type -P grep 2>/dev/null || echo '/usr/bin/grep')}"
export GAUDI_SHELL_GREP

_gaudi-shell-describe() {
	local -a GAUDI_SHELL_DESCRIBE_MODES=(enabled all)

	__check-function-parameters "$1" || return 1
	[[ -n "$2" ]] && ! _array-contains "$2" "${GAUDI_SHELL_DESCRIBE_MODES[@]}" && echo "unsupported describe mode" && return 1

	local component component_type mode file
	component=$(_gaudi-shell-pluralize-component "$1")
	component_type="$(_gaudi-shell-singularize-component "$component")"
	mode=${2:-"all"}

	printf "\n%-20s%-10s%s\n" "${component_type^}" 'Enabled?' '  Description'
	printf "%*s\n" "${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}" '' | tr ' ' -

	file=$(_gaudi-shell-component-cache-add "$component-enabled")
	[[ "$mode" = "all" ]] && file=${file/-enabled/}

	if [[ ! -s "${file}" ]]; then
		rm -f "${file}" 2>/dev/null
		local __file
		for __file in "${GAUDI_SHELL}/components/$component/"*.bash; do
			local enabled_file component_name about_text
			enabled_file="${__file##*/}"
			component_name="${enabled_file%%.*}"
			about_text="$(head -5 "$__file" | grep 'about-' | sed "s/.*about-[a-z]* '\\(.*\\)'/\\1/" 2>/dev/null)"

			if compgen -G "${GAUDI_SHELL}/components/enabled/*${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}${enabled_file}" >/dev/null 2>&1; then
				printf "%-20s${GREEN}%-10s${NC}%s\n" "$component_name" "  ◉" "    $about_text" | tee -a "${file}"
			elif [[ "$mode" = "all" ]]; then
				printf "%-20s${RED}%-10s${NC}%s\n" "$component_name" "  ◯" "    $about_text" | tee -a "${file}"
			fi
		done
	else
		cat "${file}"
	fi
}
