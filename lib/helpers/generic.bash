#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154,SC2016

# Prevent duplicate directories in PATH
# pathmunge /path/to/dir is equivalent to PATH=/path/to/dir:$PATH
# pathmunge /path/to/dir after is equivalent to PATH=$PATH:/path/to/dir
if ! type pathmunge >/dev/null 2>&1; then
	pathmunge() {
		# Plain parameter expansion only, so it behaves the same in bash (3.2
		# included) and zsh: no `read -a`, no arrays (their first index differs).
		# The list is walked from its last entry to its first, so that
		# prepending keeps the order in which the directories were given.
		local _pm_rest="$1" _pm_dir
		while [[ -n "$_pm_rest" ]]; do
			_pm_dir="${_pm_rest##*:}"
			if [[ "$_pm_rest" == *:* ]]; then
				_pm_rest="${_pm_rest%:*}"
			else
				_pm_rest=""
			fi
			[[ -n "$_pm_dir" ]] || continue
			case ":${PATH}:" in
			*":${_pm_dir}:"*) ;;
			*)
				if [[ "$2" = "after" ]]; then
					export PATH="$PATH:$_pm_dir"
				else
					export PATH="$_pm_dir:$PATH"
				fi
				;;
			esac
		done
	}
fi

# Platform-aware sed inline parameters
GAUDI_SHELL_SED_I_PARAMETERS=(-i)
case "$(uname)" in
Darwin*) GAUDI_SHELL_SED_I_PARAMETERS=(-i "") ;;
esac

PREVIEW="less"
if [[ -s /usr/bin/gloobus-preview ]]; then
	PREVIEW="gloobus-preview"
elif [[ -s /Applications/Preview.app ]]; then
	PREVIEW="/Applications/Preview.app"
fi
