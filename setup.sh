#!/usr/bin/env bash
# shellcheck shell=bash

GAUDI_SETUP_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
source "$GAUDI_SETUP_DIRECTORY/lib/colors.bash"

_read_input() {
	unset REPLY
	while ! [[ $REPLY =~ ^[yY]$ ]] && ! [[ $REPLY =~ ^[nN]$ ]]; do
		read -rp "${1} " -n 1 </dev/tty
		[[ -n $REPLY ]] && echo ""
	done
}

# Detect shell and config file
if [[ -n "$ZSH_VERSION" ]]; then
	CONFIG_FILE=".zshrc"
elif [[ "$OSTYPE" == darwin* ]]; then
	CONFIG_FILE=".bash_profile"
else
	CONFIG_FILE=".bashrc"
fi

show_usage() {
	echo -e "
Usage: ${GREEN}$0 [arguments]${NC}

Arguments:
  ${YELLOW}--help (-h)${NC}: Display this help message
  ${YELLOW}--silent (-s)${NC}: Install with defaults without prompting
  ${YELLOW}--no-modify-config (-n)${NC}: Do not modify existing config file"
	exit 0
}

for param in "$@"; do
	shift
	case "$param" in
		"--help") set -- "$@" "-h" ;;
		"--silent") set -- "$@" "-s" ;;
		"--no-modify-config") set -- "$@" "-n" ;;
		*) set -- "$@" "$param" ;;
	esac
done

OPTIND=1
while getopts "hsn" opt; do
	case "$opt" in
		"h") show_usage; exit 0 ;;
		"s") silent=true ;;
		"n") no_modify_config=true ;;
		"?") show_usage >&2; exit 1 ;;
	esac
done
shift $((OPTIND - 1))

if [[ -n $silent ]]; then
	exec >/dev/null 2>&1
fi

! [[ $silent ]] && echo -e "\n${CYAN}Installing gaudi-shell...${NC}\n"

if ! [[ $no_modify_config ]]; then
	if [[ -e "$HOME/$CONFIG_FILE" ]]; then
		cp -aL "$HOME/$CONFIG_FILE" "$HOME/$CONFIG_FILE.bak"
		echo -e "${GREEN}Your $CONFIG_FILE has been backed up to $CONFIG_FILE.bak${NC}"
	fi

	! [[ $silent ]] && _read_input "Would you like to keep your $CONFIG_FILE and append gaudi-shell template? [Yy/Nn]"

	if [[ $REPLY =~ ^[yY]$ ]]; then
		cat >> "$HOME/$CONFIG_FILE" <<TEMPLATE

# gaudi-shell
export GAUDI_SHELL="$GAUDI_SETUP_DIRECTORY"
source "\$GAUDI_SHELL/adapters/bash/init.bash"
TEMPLATE
		echo -e "${GREEN}gaudi-shell template appended to $CONFIG_FILE${NC}"
	elif [[ $REPLY =~ ^[nN]$ ]] || [[ $silent ]]; then
		cat > "$HOME/$CONFIG_FILE" <<TEMPLATE
#!/usr/bin/env bash

# gaudi-shell
export GAUDI_SHELL="$GAUDI_SETUP_DIRECTORY"
source "\$GAUDI_SHELL/adapters/bash/init.bash"
TEMPLATE
		echo -e "${YELLOW}Wrote gaudi-shell template to ~/$CONFIG_FILE${NC}"
	fi
fi

# Source core for enabling defaults
source "$GAUDI_SETUP_DIRECTORY/lib/log.bash"
source "$GAUDI_SETUP_DIRECTORY/lib/colors.bash"
source "$GAUDI_SETUP_DIRECTORY/lib/gaudi-shell.bash"
for helper in "$GAUDI_SETUP_DIRECTORY"/lib/helpers/*.bash; do source "$helper"; done

export GAUDI_SHELL="$GAUDI_SETUP_DIRECTORY"

echo -e "\n${MAGENTA}Enabling gaudi-shell default components${NC}"

_gaudi-shell-enable completion system 2>/dev/null
_gaudi-shell-enable plugin base 2>/dev/null
_gaudi-shell-enable alias general 2>/dev/null

echo -e "
${GREEN}Installation finished successfully!${NC}
${MAGENTA}To start using it, open a new tab or 'source ${HOME}/$CONFIG_FILE'${NC}
"
