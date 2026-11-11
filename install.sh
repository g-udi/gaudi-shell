#!/usr/bin/env bash
# shellcheck shell=bash

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

	"$GAUDI_SHELL/setup.sh" "$@"
}

if [[ -d "$GAUDI_SHELL" ]]; then
	echo "You already have gaudi-shell installed.."
	# Asked once. No answer (end of input) or anything other than y or n stops
	# here without changing the install.
	printf "Do you want to set up a fresh installation of gaudi-shell? [y/n] "
	if ! read -r REPLY; then
		printf "\n%s\n" "No answer: nothing was changed." >&2
		exit 1
	fi
	case "$REPLY" in
	[yY])
		rm -rf "$GAUDI_SHELL"
		__install "$@"
		;;
	[nN])
		printf "\n%s\n" "Running a gaudi-shell update to pull latest changes ..."
		git -C "$GAUDI_SHELL" pull
		;;
	*)
		printf "%s\n" "Please answer y or n. Nothing was changed." >&2
		exit 1
		;;
	esac
else
	__install "$@"
fi
