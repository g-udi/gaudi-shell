#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2120

GAUDI_SHELL="$HOME/.gaudi-shell"

__install() {
	# Prevent the cloned repository from having insecure permissions. Failing to do
	# so causes compinit() calls to fail with "command not found: compdef" errors
	# for users with insecure umasks (e.g., "002", allowing group writability). Note
	# that this will be ignored under Cygwin by default, as Windows ACLs take
	# precedence over umasks except for filesystems mounted with option "noacl".
	umask g-w,o-w

	env git clone --depth=1 --recurse-submodules https://github.com/g-udi/gaudi-shell.git "$GAUDI_SHELL" || {
		printf "%s\n" "Error: Cloning of gaudi into this machine failed :("
		exit 1
	}

	source "$GAUDI_SHELL/setup.sh" "$@"
}

if [[ -d "$GAUDI_SHELL" ]]; then
	echo "You already have gaudi-shell installed.."
	unset REPLY
	while ! [[ $REPLY =~ ^[yY]$ ]] && ! [[ $REPLY =~ ^[nN]$ ]]; do
		printf "Do you want to set up a fresh installation of gaudi-shell? [Yy/nN] "
		read -r REPLY
		if [[ $REPLY =~ ^[yY]$ ]]; then
			rm -rf "$GAUDI_SHELL"
			__install "$@"
		else
			echo ""
			printf "\n%s\n" "Running a gaudi-shell update to pull latest changes ..."
			git -C "$GAUDI_SHELL" pull
		fi
	done
else
	__install "$@"
fi
