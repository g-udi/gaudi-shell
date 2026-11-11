# shellcheck shell=bash
# shellcheck disable=SC2207,SC1091

# about-completion 'Tab completions for the gshell command'

# The commands and their fixed arguments come from the one table in
# lib/gaudi-shell.bash (_gaudi-shell-verbs). This file only adds what has to
# be looked up (component and profile names) and the glue for each shell; the
# zsh glue is in gaudi-shell.completions.zsh.

# --- Helper: list available but not enabled components ---
_gaudi-shell-comp-list-available-not-enabled() {
	# zsh: leave a pattern without matches as it is instead of raising an error
	[[ -n "${ZSH_VERSION:-}" ]] && setopt local_options no_nomatch
	local subdirectory="$1"
	local result=""
	local f file_entity

	while IFS= read -r f; do
		[[ -n "$f" ]] || continue
		file_entity="${f##*/}"
		_gaudi-shell-enabled-link "$file_entity" >/dev/null || result="${result} ${file_entity%%.*}"
	done < <(_gaudi-shell-component-files "${subdirectory}")
	echo "all ${result}"
}

# --- Helper: list enabled components ---
_gaudi-shell-comp-list-enabled() {
	[[ -n "${ZSH_VERSION:-}" ]] && setopt local_options no_nomatch
	local subdirectory="$1"
	local result=""
	local f name

	for f in "${GAUDI_SHELL}/components/enabled/"*".${subdirectory}.bash"; do
		[[ -f "$f" ]] || continue
		name="${f##*/}"
		name="${name#*"${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}"}"
		result="${result} ${name%%.*}"
	done
	echo "all ${result}"
}

# --- Helper: list saved profiles ---
_gaudi-shell-comp-list-profiles() {
	[[ -n "${ZSH_VERSION:-}" ]] && setopt local_options no_nomatch
	local result=""
	local f name

	for f in "${GAUDI_SHELL}/profiles/"*.gaudi-shell; do
		[[ -f "$f" ]] || continue
		name="${f##*/}"
		result="${result} ${name%.gaudi-shell}"
	done
	echo "${result}"
}

# Print the words (separated by spaces) that can follow the command $1 as its
# argument number $2; $3 is its first argument when that is already typed.
# Used by the completion of both shells.
_gaudi-shell-comp-words() {
	local verb="$1" position="$2" first="${3:-}"

	case "${verb}" in
	enable | disable)
		if [[ "${position}" -eq 1 ]]; then
			_gaudi-shell-verb-field "${verb}" 4
		elif __check-function-parameters "${first}"; then
			first="$(_gaudi-shell-pluralize-component "${first}")"
			if [[ "${verb}" == "enable" ]]; then
				_gaudi-shell-comp-list-available-not-enabled "${first}"
			else
				_gaudi-shell-comp-list-enabled "${first}"
			fi
		fi
		;;
	profile)
		if [[ "${position}" -eq 1 ]]; then
			_gaudi-shell-verb-field "${verb}" 4
		elif [[ "${position}" -eq 2 ]]; then
			case "${first}" in
			save | load | rm) _gaudi-shell-comp-list-profiles ;;
			esac
		fi
		;;
	search)
		# Terms are free text; the flags can go anywhere
		_gaudi-shell-verb-field "${verb}" 4
		;;
	*)
		if [[ "${position}" -eq 1 ]]; then
			_gaudi-shell-verb-field "${verb}" 4
		elif [[ "${position}" -eq 2 ]]; then
			_gaudi-shell-verb-field "${verb}" 5
		fi
		;;
	esac
	return 0
}

# =====================================================================
# BASH completion
# =====================================================================
if [[ -n "${BASH_VERSION:-}" ]]; then

	_gaudi-shell-comp() {
		COMPREPLY=()
		local current="${COMP_WORDS[COMP_CWORD]}"
		local candidates

		if [[ "${COMP_CWORD}" -le 1 ]]; then
			candidates="$(_gaudi-shell-verb-names)"
		else
			candidates="$(_gaudi-shell-comp-words "${COMP_WORDS[1]}" "$((COMP_CWORD - 1))" "${COMP_WORDS[2]:-}")"
		fi

		COMPREPLY=($(compgen -W "${candidates}" -- "${current}"))
		return 0
	}

	complete -F _gaudi-shell-comp gshell
	complete -F _gaudi-shell-comp g
fi

# =====================================================================
# ZSH completion — loaded from separate file to avoid bash parse errors
# =====================================================================
if [[ -n "${ZSH_VERSION:-}" ]]; then
	source "${GAUDI_SHELL}/components/host/gaudi-shell.completions.zsh"
fi
