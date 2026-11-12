#!/usr/bin/env bash
# shellcheck shell=bash

GAUDI_SHELL="$HOME/.gaudi-shell"

# Fetch the shared components (the aliases, completions and plugins
# submodules; not bin/bats-*, which are test tools for developers) and repair
# enabled links left by an older layout. This script runs before the framework
# is on disk, so it has no copy of the helpers: once the clone is there it
# uses the ones in lib/helpers/components.bash, the same that "gshell update"
# and setup.sh use. Arguments are passed to "git submodule update".
__update_components() {
	[[ -f "$GAUDI_SHELL/lib/helpers/components.bash" ]] || return 1
	# shellcheck disable=SC1091
	source "$GAUDI_SHELL/lib/helpers/components.bash"
	_gaudi-shell-update-component-submodules "$GAUDI_SHELL" "$@" || return 1
	_gaudi-shell-migrate-enabled-links
}

# The folders of the install that hold the user's own files.
GAUDI_SHELL_USER_FOLDERS=(profiles components/custom)
GAUDI_SHELL_KEPT=""

# A fresh installation deletes the install directory. The user's folders are
# moved to a temporary directory first ($1 = "aside") and into the new clone
# afterwards ($1 = "back").
__keep_user_files() {
	local folder
	if [[ "$1" == "aside" ]]; then
		GAUDI_SHELL_KEPT="$(mktemp -d "${TMPDIR:-/tmp}/gaudi-shell-kept.XXXXXX")" || return 1
		for folder in "${GAUDI_SHELL_USER_FOLDERS[@]}"; do
			[[ -d "$GAUDI_SHELL/$folder" ]] || continue
			mkdir -p "$(dirname "$GAUDI_SHELL_KEPT/$folder")" || return 1
			mv "$GAUDI_SHELL/$folder" "$GAUDI_SHELL_KEPT/$folder" || return 1
		done
		return 0
	fi

	[[ -n "$GAUDI_SHELL_KEPT" ]] || return 0
	for folder in "${GAUDI_SHELL_USER_FOLDERS[@]}"; do
		[[ -d "$GAUDI_SHELL_KEPT/$folder" ]] || continue
		# An empty folder of the same name in the clone makes way
		rmdir "$GAUDI_SHELL/$folder" 2>/dev/null
		[[ ! -e "$GAUDI_SHELL/$folder" ]] || return 1
		mkdir -p "$(dirname "$GAUDI_SHELL/$folder")" || return 1
		mv "$GAUDI_SHELL_KEPT/$folder" "$GAUDI_SHELL/$folder" || return 1
	done
	rmdir "$GAUDI_SHELL_KEPT/components" 2>/dev/null
	rmdir "$GAUDI_SHELL_KEPT" 2>/dev/null
	GAUDI_SHELL_KEPT=""
}

# Say where the user's folders are when they could not be put back.
__report_kept() {
	[[ -n "$GAUDI_SHELL_KEPT" ]] || return 0
	printf "%s\n" "Your profiles and custom components are in $GAUDI_SHELL_KEPT" >&2
}

# Bring an existing install up to date. On a branch that is "git pull".
# "gshell update" leaves the install on a tag or a remote branch (a detached
# HEAD), where "git pull" cannot work: there the latest release tag is
# checked out instead.
__update_checkout() {
	local latest
	if git -C "$GAUDI_SHELL" symbolic-ref -q HEAD >/dev/null 2>&1; then
		git -C "$GAUDI_SHELL" pull
		return
	fi
	git -C "$GAUDI_SHELL" fetch --tags origin || return 1
	latest="$(git -C "$GAUDI_SHELL" describe --tags "$(git -C "$GAUDI_SHELL" rev-list --tags --max-count=1 2>/dev/null)" 2>/dev/null)"
	[[ -n "$latest" ]] || return 1
	git -C "$GAUDI_SHELL" checkout "$latest"
}

__install() {
	# Prevent the cloned repository from having insecure permissions. Failing to do
	# so causes compinit() calls to fail with "command not found: compdef" errors
	# for users with insecure umasks (e.g., "002", allowing group writability). Note
	# that this will be ignored under Cygwin by default, as Windows ACLs take
	# precedence over umasks except for filesystems mounted with option "noacl".
	umask g-w,o-w

	env git clone --depth=1 https://github.com/g-udi/gaudi-shell.git "$GAUDI_SHELL" || {
		printf "%s\n" "Error: Cloning of gaudi into this machine failed :("
		__report_kept
		exit 1
	}

	__keep_user_files back || {
		printf "%s\n" "Error: Could not put your profiles and custom components back :(" >&2
		__report_kept
		exit 1
	}

	__update_components --depth=1 || {
		printf "%s\n" "Error: Fetching the shared components failed :(" >&2
		printf "%s\n" "Try again with: git -C \"$GAUDI_SHELL\" submodule update --init components/aliases components/completions components/plugins" >&2
		exit 1
	}

	"$GAUDI_SHELL/setup.sh" "$@"
}

if [[ -d "$GAUDI_SHELL" ]]; then
	echo "You already have gaudi-shell installed.."
	# Asked once. No answer (end of input) or anything other than y or n stops
	# here without changing the install.
	printf "Do you want to set up a fresh installation of gaudi-shell (your profiles and custom components are kept)? [y/n] "
	if ! read -r REPLY; then
		printf "\n%s\n" "No answer: nothing was changed." >&2
		exit 1
	fi
	case "$REPLY" in
	[yY])
		__keep_user_files aside || {
			printf "%s\n" "Error: Could not set your profiles and custom components aside. Nothing was deleted." >&2
			__report_kept
			exit 1
		}
		rm -rf "$GAUDI_SHELL"
		__install "$@"
		;;
	[nN])
		printf "\n%s\n" "Updating gaudi-shell to the latest changes ..."
		__update_checkout || {
			printf "%s\n" "Error: The update failed. Nothing else was changed; try 'gshell update' in a new shell." >&2
			exit 1
		}
		__update_components || printf "%s\n" "The shared components could not be updated: run 'gshell migrate' in a new shell." >&2
		;;
	*)
		printf "%s\n" "Please answer y or n. Nothing was changed." >&2
		exit 1
		;;
	esac
else
	__install "$@"
fi
