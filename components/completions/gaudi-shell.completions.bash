# shellcheck shell=bash
# shellcheck disable=SC2207

# about-completion 'Tab completions for the gaudi command'

_gaudi-shell-comp-list-available-not-enabled() {
	local subdirectory="$1"
	local available_things=""
	local f

	for f in "${GAUDI_SHELL}/components/${subdirectory}/"*.bash; do
		[[ -f "$f" ]] || continue
		local file_entity
		file_entity=$(basename "$f")
		if ! ls "${GAUDI_SHELL}/components/enabled/"*"${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}${file_entity}" &>/dev/null; then
			local name="${file_entity%%.*}"
			available_things="${available_things} ${name}"
		fi
	done

	COMPREPLY=($(compgen -W "all ${available_things}" -- "${COMP_WORDS[COMP_CWORD]}"))
}

_gaudi-shell-comp-list-enabled() {
	local subdirectory="$1"
	local enabled_things=""
	local f

	for f in "${GAUDI_SHELL}/components/enabled/"*".${subdirectory}.bash"; do
		[[ -f "$f" ]] || continue
		local name
		name=$(basename "$f")
		name="${name#*"${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}"}"
		name="${name%%.*}"
		enabled_things="${enabled_things} ${name}"
	done

	COMPREPLY=($(compgen -W "all ${enabled_things}" -- "${COMP_WORDS[COMP_CWORD]}"))
}

_gaudi-shell-comp() {
	local BASE_OPTIONS="show enable disable reload restart search update backup restore profile doctor help version"

	COMPREPLY=()
	local current="${COMP_WORDS[COMP_CWORD]}"
	local verb="${COMP_WORDS[1]:-}"
	local file_type="${COMP_WORDS[2]:-}"

	case "${verb}" in
		show)
			COMPREPLY=($(compgen -W "aliases completions plugins" -- "${current}"))
			return 0
			;;
		help)
			COMPREPLY=($(compgen -W "aliases completions plugins" -- "${current}"))
			return 0
			;;
		doctor)
			COMPREPLY=($(compgen -W "errors warnings all" -- "${current}"))
			return 0
			;;
		profile)
			if [[ "${COMP_CWORD}" -eq 2 ]]; then
				COMPREPLY=($(compgen -W "save load list rm" -- "${current}"))
			elif [[ "${COMP_CWORD}" -eq 3 ]]; then
				local profiles=""
				for f in "${GAUDI_SHELL}/profiles/"*.gaudi-shell; do
					[[ -f "$f" ]] || continue
					profiles="${profiles} $(basename "$f" .gaudi-shell)"
				done
				COMPREPLY=($(compgen -W "${profiles}" -- "${current}"))
			fi
			return 0
			;;
		update)
			COMPREPLY=($(compgen -W "stable dev all" -- "${current}"))
			return 0
			;;
		reload | restart | search | version | backup | restore)
			return 0
			;;
		enable | disable)
			if [[ "${COMP_CWORD}" -eq 2 ]]; then
				COMPREPLY=($(compgen -W "alias plugin completion" -- "${current}"))
				return 0
			fi
			local suffix
			if [[ "${verb}" == "enable" ]]; then
				suffix="available-not-enabled"
			else
				suffix="enabled"
			fi
			case "${file_type}" in
				alias) "_gaudi-shell-comp-list-${suffix}" aliases ;;
				plugin) "_gaudi-shell-comp-list-${suffix}" plugins ;;
				completion) "_gaudi-shell-comp-list-${suffix}" completions ;;
			esac
			return 0
			;;
	esac

	COMPREPLY=($(compgen -W "${BASE_OPTIONS}" -- "${current}"))
	return 0
}

# Register completion for both the full command and the alias
complete -F _gaudi-shell-comp gaudi
complete -F _gaudi-shell-comp g
