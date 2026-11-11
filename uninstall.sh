#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC1090,SC1091

# Removes gaudi-shell: takes its lines out of the shell config file and deletes
# the install directory. Everything else in the config file is left as it is.

# The shell config files to clean, as names relative to $HOME: the one named
# by GAUDI_SHELL_PROFILE when it is set, otherwise every usual config file
# that loads gaudi-shell.
_gaudi_shell_uninstall_configs() {
	local name

	if [[ -n "${GAUDI_SHELL_PROFILE:-}" ]]; then
		printf '%s\n' "$GAUDI_SHELL_PROFILE"
		return 0
	fi
	for name in .zshrc .bash_profile .bashrc; do
		_gaudi_shell_uninstall_has_block "$HOME/$name" && printf '%s\n' "$name"
	done
	return 0
}

# True when the file $1 sources a gaudi-shell adapter.
_gaudi_shell_uninstall_has_block() {
	[[ -f "$1" ]] || return 1
	grep -Eq '^[[:space:]]*(source|\.)[[:space:]].*adapters/(bash/init\.bash|zsh/init\.zsh)' "$1"
}

# Print the file $1 without the lines setup.sh added:
#   # gaudi-shell
#   export GAUDI_SHELL="..."
#   source "$GAUDI_SHELL/adapters/<shell>/init.<shell>"
# and without the empty line setup.sh puts in front of them.
_gaudi_shell_uninstall_filter() {
	awk '
		function flush() { if (held) { print ""; held = 0 } }
		/^[[:space:]]*# gaudi-shell[[:space:]]*$/ { held = 0; next }
		/^[[:space:]]*export[[:space:]]+GAUDI_SHELL=/ { flush(); next }
		/^[[:space:]]*(source|\.)[[:space:]].*adapters\/(bash\/init\.bash|zsh\/init\.zsh)/ { flush(); next }
		/^$/ { flush(); held = 1; next }
		{ flush(); print }
		END { flush() }
	' "$1"
}

# Take the gaudi-shell lines out of the config file $1. A copy of the file as
# it was is kept next to it; the file itself is rewritten in place, so a
# symlinked config file stays a symlink.
_gaudi_shell_uninstall_clean() {
	local config="$1" copy stamp n=0 cleaned

	copy="$config.before-gaudi-uninstall"
	if [[ -e "$copy" || -L "$copy" ]]; then
		stamp="$(date +%Y%m%d%H%M%S)"
		copy="$config.before-gaudi-uninstall.$stamp"
		while [[ -e "$copy" || -L "$copy" ]]; do
			n=$((n + 1))
			copy="$config.before-gaudi-uninstall.$stamp.$n"
		done
	fi

	cleaned="$(mktemp "${TMPDIR:-/tmp}/gaudi-shell-uninstall.XXXXXX")" || return 1
	if ! _gaudi_shell_uninstall_filter "$config" >"$cleaned"; then
		rm -f "$cleaned"
		return 1
	fi
	if ! cp -pL "$config" "$copy"; then
		rm -f "$cleaned"
		return 1
	fi
	if ! cat "$cleaned" >"$config"; then
		rm -f "$cleaned"
		return 1
	fi
	rm -f "$cleaned"
	echo -e "${GREEN:-}Removed gaudi-shell from $config (the file as it was: ${copy##*/})${NC:-}"
}

_gaudi_shell_uninstall() {
	local install_dir="${GAUDI_SHELL:-$HOME/.gaudi-shell}"
	local name config cleaned_any=""
	local -a configs
	configs=()

	[[ -f "$install_dir/lib/colors.bash" ]] && source "$install_dir/lib/colors.bash"

	if [[ -z "${HOME:-}" ]]; then
		echo "Error: HOME is not set, so the shell config file cannot be found. Nothing was changed." >&2
		return 1
	fi

	while IFS= read -r name; do
		[[ -n "$name" ]] && configs+=("$name")
	done < <(_gaudi_shell_uninstall_configs)

	# Fail before touching anything when it is not clear which file to clean.
	if [[ ${#configs[@]} -eq 0 ]]; then
		{
			echo "Error: could not tell which shell config file loads gaudi-shell."
			echo "Nothing was changed. Name the file (relative to your home directory) and run again:"
			echo "  GAUDI_SHELL_PROFILE=.zshrc $install_dir/uninstall.sh"
		} >&2
		return 1
	fi

	# Never delete anything but a gaudi-shell checkout.
	if [[ -d "$install_dir" && ! -f "$install_dir/gaudi_shell.sh" ]]; then
		echo "Error: $install_dir does not look like a gaudi-shell install. Nothing was changed." >&2
		return 1
	fi

	for name in "${configs[@]}"; do
		config="$HOME/$name"
		if _gaudi_shell_uninstall_has_block "$config" || grep -Eq '^[[:space:]]*export[[:space:]]+GAUDI_SHELL=' "$config" 2>/dev/null; then
			if ! _gaudi_shell_uninstall_clean "$config"; then
				echo "Error: could not update $config. Nothing else was changed." >&2
				return 1
			fi
			cleaned_any=1
			if grep -q 'GAUDI_SHELL' "$config"; then
				echo -e "${YELLOW:-}$config still has lines that mention GAUDI_SHELL (settings you added); remove them if you no longer need them.${NC:-}"
			fi
		elif [[ -e "$config" ]]; then
			echo -e "${YELLOW:-}$config does not load gaudi-shell, left unchanged.${NC:-}"
		else
			echo -e "${YELLOW:-}$config not found, nothing to clean.${NC:-}"
		fi
		if [[ -e "$config.bak" ]]; then
			echo "The backup made when gaudi-shell was installed is still there: $config.bak"
		fi
	done

	[[ -d "$install_dir" ]] && rm -rf "$install_dir"

	echo ""
	echo -e "${GREEN:-}un-installation finished successfully! Sorry to see you go!${NC:-}"
	echo ""
	echo "Final steps to complete the un-installation:"
	echo "  -> Open a new shell/tab/terminal"
	[[ -n "$cleaned_any" ]] || echo "  -> No shell config file was changed"
	return 0
}

_gaudi_shell_uninstall
_gaudi_shell_uninstall_status=$?
unset -f _gaudi_shell_uninstall _gaudi_shell_uninstall_configs _gaudi_shell_uninstall_has_block \
	_gaudi_shell_uninstall_filter _gaudi_shell_uninstall_clean
# Works when the script is run and when it is sourced
# shellcheck disable=SC2317
return "$_gaudi_shell_uninstall_status" 2>/dev/null || exit "$_gaudi_shell_uninstall_status"
