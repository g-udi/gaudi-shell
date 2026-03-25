#!/usr/bin/env bash
# shellcheck shell=bash

: "${GAUDI_SHELL:=$HOME/.gaudi-shell}"

BACKUP_FILE=$GAUDI_SHELL_PROFILE.bak

if [[ ! -e "$HOME/$BACKUP_FILE" ]]; then
	echo -e "${YELLOW}Backup file $HOME/$BACKUP_FILE not found.${NC}" >&2

	test -w "$HOME/$GAUDI_SHELL_PROFILE" \
		&& mv "$HOME/$GAUDI_SHELL_PROFILE" "$HOME/$GAUDI_SHELL_PROFILE.uninstall" \
		&& echo -e "${GREEN}Moved your $HOME/$GAUDI_SHELL_PROFILE to $HOME/$GAUDI_SHELL_PROFILE.uninstall.${NC}"
else
	test -w "$HOME/$BACKUP_FILE" \
		&& cp -a "$HOME/$BACKUP_FILE" "$HOME/$GAUDI_SHELL_PROFILE" \
		&& rm "$HOME/$BACKUP_FILE" \
		&& echo -e "${GREEN}Your original $GAUDI_SHELL_PROFILE has been restored.${NC}"
fi

rm -rf "$GAUDI_SHELL"

echo ""
echo -e "${GREEN}un-installation finished successfully! Sorry to see you go!${NC}"
echo ""
echo "Final steps to complete the un-installation:"
echo "  -> Open a new shell/tab/terminal"
