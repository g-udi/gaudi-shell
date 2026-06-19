#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC1090,SC1091

GAUDI_SETUP_SOURCE="${BASH_SOURCE[0]:-$0}"
GAUDI_SETUP_DIRECTORY="$(cd "$(dirname "$GAUDI_SETUP_SOURCE")" && pwd)"
source "$GAUDI_SETUP_DIRECTORY/lib/colors.bash"

_read_input() {
	unset REPLY
	while ! [[ $REPLY =~ ^[yY]$ ]] && ! [[ $REPLY =~ ^[nN]$ ]]; do
		read -rp "${1} " -n 1 </dev/tty
		[[ -n $REPLY ]] && echo ""
	done
}

show_usage() {
	echo -e "
Usage: ${GREEN}$0 [arguments]${NC}

Arguments:
  ${YELLOW}--help (-h)${NC}: Display this help message
  ${YELLOW}--silent (-s)${NC}: Install with defaults without prompting
  ${YELLOW}--no-modify-config (-n)${NC}: Do not modify existing config file
  ${YELLOW}--shell bash|zsh${NC}: Install for the selected shell instead of auto-detecting"
}

_die() {
	printf "%s\n" "Error: $*" >&2
	exit 1
}

_normalize_shell() {
	local shell_name="${1##*/}"
	case "$shell_name" in
	bash | zsh)
		printf "%s\n" "$shell_name"
		;;
	*)
		return 1
		;;
	esac
}

_detect_target_shell() {
	local detected

	if [[ -n "${target_shell:-}" ]]; then
		_normalize_shell "$target_shell" || _die "Unsupported shell '$target_shell'. Use bash or zsh."
		return
	fi

	if [[ -n "${GAUDI_SHELL_TARGET:-}" ]]; then
		_normalize_shell "$GAUDI_SHELL_TARGET" || _die "Unsupported GAUDI_SHELL_TARGET '$GAUDI_SHELL_TARGET'. Use bash or zsh."
		return
	fi

	if [[ -n "${SHELL:-}" ]] && detected="$(_normalize_shell "$SHELL")"; then
		printf "%s\n" "$detected"
		return
	fi

	if [[ -n "${ZSH_VERSION:-}" ]]; then
		printf "%s\n" "zsh"
		return
	fi

	printf "%s\n" "bash"
}

_set_shell_config() {
	if ! GAUDI_TARGET_SHELL="$(_detect_target_shell)"; then
		exit 1
	fi

	case "$GAUDI_TARGET_SHELL" in
	zsh)
		CONFIG_FILE=".zshrc"
		ADAPTER="adapters/zsh/init.zsh"
		;;
	bash)
		if [[ "$OSTYPE" == darwin* ]]; then
			CONFIG_FILE=".bash_profile"
		else
			CONFIG_FILE=".bashrc"
		fi
		ADAPTER="adapters/bash/init.bash"
		;;
	esac
}

_write_gaudi_template() {
	local destination="$HOME/$CONFIG_FILE"
	local mode="$1"

	if [[ "$mode" == "append" ]]; then
		cat >>"$destination" <<TEMPLATE

# gaudi-shell
export GAUDI_SHELL="$GAUDI_SETUP_DIRECTORY"
source "\$GAUDI_SHELL/$ADAPTER"
TEMPLATE
		return
	fi

	if [[ "$GAUDI_TARGET_SHELL" == "bash" ]]; then
		cat >"$destination" <<TEMPLATE
#!/usr/bin/env bash

# gaudi-shell
export GAUDI_SHELL="$GAUDI_SETUP_DIRECTORY"
source "\$GAUDI_SHELL/$ADAPTER"
TEMPLATE
	else
		cat >"$destination" <<TEMPLATE
# gaudi-shell
export GAUDI_SHELL="$GAUDI_SETUP_DIRECTORY"
source "\$GAUDI_SHELL/$ADAPTER"
TEMPLATE
	fi
}

_parse_args() {
	silent=false
	no_modify_config=false
	target_shell=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_usage
			exit 0
			;;
		-s | --silent)
			silent=true
			;;
		-n | --no-modify-config)
			no_modify_config=true
			;;
		--shell)
			shift
			[[ $# -gt 0 ]] || _die "--shell requires a value: bash or zsh"
			target_shell="$1"
			;;
		--shell=*)
			target_shell="${1#*=}"
			;;
		*)
			printf "%s\n" "Unknown argument: $1" >&2
			show_usage >&2
			exit 1
			;;
		esac
		shift
	done
}

_setup_gaudi_shell() {
	! [[ $silent == true ]] && echo -e "\n${CYAN}Installing gaudi-shell for $GAUDI_TARGET_SHELL...${NC}\n"

	if ! [[ $no_modify_config == true ]]; then
		if [[ -e "$HOME/$CONFIG_FILE" ]]; then
			cp -aL "$HOME/$CONFIG_FILE" "$HOME/$CONFIG_FILE.bak"
			echo -e "${GREEN}Your $CONFIG_FILE has been backed up to $CONFIG_FILE.bak${NC}"
		fi

		! [[ $silent == true ]] && _read_input "Would you like to keep your $CONFIG_FILE and append gaudi-shell template? [Yy/Nn]"

		if [[ $REPLY =~ ^[yY]$ ]]; then
			_write_gaudi_template append
			echo -e "${GREEN}gaudi-shell template appended to $CONFIG_FILE${NC}"
		elif [[ $REPLY =~ ^[nN]$ ]] || [[ $silent == true ]]; then
			_write_gaudi_template replace
			echo -e "${YELLOW}Wrote gaudi-shell template to ~/$CONFIG_FILE${NC}"
		fi
	fi

	# Source core for enabling defaults
	export GAUDI_SHELL="$GAUDI_SETUP_DIRECTORY"
	export GAUDI_SHELL_CURRENT="$GAUDI_TARGET_SHELL"

	source "$GAUDI_SETUP_DIRECTORY/lib/log.bash"
	source "$GAUDI_SETUP_DIRECTORY/lib/gaudi-shell.bash"
	for helper in "$GAUDI_SETUP_DIRECTORY"/lib/helpers/*.bash; do source "$helper"; done

	echo -e "\n${MAGENTA}Enabling gaudi-shell default components${NC}"

	_gaudi-shell-enable completion gaudi-shell 2>/dev/null
	_gaudi-shell-enable completion system 2>/dev/null
	_gaudi-shell-enable plugin base 2>/dev/null
	_gaudi-shell-enable alias general 2>/dev/null

	echo -e "
${GREEN}Installation finished successfully!${NC}
${MAGENTA}To start using it, open a new tab or 'source ${HOME}/$CONFIG_FILE'${NC}
"
}

_parse_args "$@"
_set_shell_config

if [[ $silent == true ]]; then
	_setup_gaudi_shell >/dev/null 2>&1
else
	_setup_gaudi_shell
fi
