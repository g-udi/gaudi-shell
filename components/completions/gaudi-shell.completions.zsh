#!/usr/bin/env zsh
# Zsh-native tab completion for gaudi / g commands

_gaudi-shell-zsh-comp() {
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
