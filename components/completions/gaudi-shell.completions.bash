# shellcheck shell=bash
# shellcheck disable=SC2207,SC2128

# about-completion 'Tab completions for the gaudi command'

# --- Helper: list available but not enabled components ---
_gaudi-shell-comp-list-available-not-enabled() {
	local subdirectory="$1"
	local result=""
	local f file_entity name

	for f in "${GAUDI_SHELL}/components/${subdirectory}/"*.bash; do
		[[ -f "$f" ]] || continue
		file_entity=$(basename "$f")
		if ! ls "${GAUDI_SHELL}/components/enabled/"*"${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}${file_entity}" &>/dev/null; then
			name="${file_entity%%.*}"
			result="${result} ${name}"
		fi
	done
	echo "all ${result}"
}

# --- Helper: list enabled components ---
_gaudi-shell-comp-list-enabled() {
	local subdirectory="$1"
	local result=""
	local f name

	for f in "${GAUDI_SHELL}/components/enabled/"*".${subdirectory}.bash"; do
		[[ -f "$f" ]] || continue
		name=$(basename "$f")
		name="${name#*"${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}"}"
		name="${name%%.*}"
		result="${result} ${name}"
	done
	echo "all ${result}"
}

# --- Helper: list saved profiles ---
_gaudi-shell-comp-list-profiles() {
	local result=""
	local f

	for f in "${GAUDI_SHELL}/profiles/"*.gaudi-shell; do
		[[ -f "$f" ]] || continue
		result="${result} $(basename "$f" .gaudi-shell)"
	done
	echo "${result}"
}

# =====================================================================
# BASH completion
# =====================================================================
if [[ -n "${BASH_VERSION:-}" ]]; then

	_gaudi-shell-comp() {
		local BASE_OPTIONS="show enable disable reload restart search update backup restore profile doctor help version"

		COMPREPLY=()
		local current="${COMP_WORDS[COMP_CWORD]}"
		local verb="${COMP_WORDS[1]:-}"
		local file_type="${COMP_WORDS[2]:-}"

		case "${verb}" in
			show | help)
				COMPREPLY=($(compgen -W "aliases completions plugins" -- "${current}"))
				;;
			doctor)
				COMPREPLY=($(compgen -W "errors warnings all" -- "${current}"))
				;;
			profile)
				if [[ "${COMP_CWORD}" -eq 2 ]]; then
					COMPREPLY=($(compgen -W "save load list rm" -- "${current}"))
				elif [[ "${COMP_CWORD}" -eq 3 ]]; then
					COMPREPLY=($(compgen -W "$(_gaudi-shell-comp-list-profiles)" -- "${current}"))
				fi
				;;
			update)
				COMPREPLY=($(compgen -W "stable dev all" -- "${current}"))
				;;
			reload | restart | search | version | backup | restore)
				;;
			enable | disable)
				if [[ "${COMP_CWORD}" -eq 2 ]]; then
					COMPREPLY=($(compgen -W "alias plugin completion" -- "${current}"))
				else
					local suffix="available-not-enabled"
					[[ "${verb}" == "disable" ]] && suffix="enabled"
					case "${file_type}" in
						alias) COMPREPLY=($(compgen -W "$(_gaudi-shell-comp-list-${suffix} aliases)" -- "${current}")) ;;
						plugin) COMPREPLY=($(compgen -W "$(_gaudi-shell-comp-list-${suffix} plugins)" -- "${current}")) ;;
						completion) COMPREPLY=($(compgen -W "$(_gaudi-shell-comp-list-${suffix} completions)" -- "${current}")) ;;
					esac
				fi
				;;
			*)
				COMPREPLY=($(compgen -W "${BASE_OPTIONS}" -- "${current}"))
				;;
		esac
		return 0
	}

	complete -F _gaudi-shell-comp gaudi
	complete -F _gaudi-shell-comp g
fi

# =====================================================================
# ZSH completion
# =====================================================================
if [[ -n "${ZSH_VERSION:-}" ]]; then

	_gaudi-shell-zsh-comp() {
		# Restore native zsh mode inside completion (KSH_ARRAYS breaks word indexing)
		emulate -L zsh

		local verb="${words[2]:-}"
		local file_type="${words[3]:-}"

		_gaudi_zsh_list_components() {
			local subdirectory="$1" mode="$2"
			local names=()
			local f name

			if [[ "$mode" == "enabled" ]]; then
				for f in "${GAUDI_SHELL}/components/enabled/"*".${subdirectory}.bash"(N); do
					name="${f:t}"
					name="${name#*___}"
					name="${name%%.*}"
					names+=("$name")
				done
			else
				for f in "${GAUDI_SHELL}/components/${subdirectory}/"*.bash(N); do
					local file_entity="${f:t}"
					if ! ls "${GAUDI_SHELL}/components/enabled/"*"___${file_entity}" &>/dev/null; then
						name="${file_entity%%.*}"
						names+=("$name")
					fi
				done
			fi
			compadd -- all "${names[@]}"
		}

		case "${verb}" in
			show | help)
				compadd -- aliases completions plugins
				;;
			doctor)
				compadd -- errors warnings all
				;;
			profile)
				if (( CURRENT == 3 )); then
					compadd -- save load list rm
				elif (( CURRENT == 4 )); then
					local profiles=()
					local f
					for f in "${GAUDI_SHELL}/profiles/"*.gaudi-shell(N); do
						profiles+=("${${f:t}%.gaudi-shell}")
					done
					compadd -- "${profiles[@]}"
				fi
				;;
			update)
				compadd -- stable dev all
				;;
			reload | restart | search | version | backup | restore)
				;;
			enable | disable)
				if (( CURRENT == 3 )); then
					compadd -- alias plugin completion
				else
					local mode="available"
					[[ "${verb}" == "disable" ]] && mode="enabled"
					case "${file_type}" in
						alias) _gaudi_zsh_list_components aliases "$mode" ;;
						plugin) _gaudi_zsh_list_components plugins "$mode" ;;
						completion) _gaudi_zsh_list_components completions "$mode" ;;
					esac
				fi
				;;
			*)
				compadd -- show enable disable reload restart search update backup restore profile doctor help version
				;;
		esac
	}

	compdef _gaudi-shell-zsh-comp gaudi
	compdef _gaudi-shell-zsh-comp g
fi
