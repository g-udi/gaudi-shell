#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

# Terminal color definitions — works in bash and zsh.
# Only export colors if the terminal supports them.
# The values hold the escape character itself ($'...'), not the two characters
# "\e": bash 3.2's `echo -e` does not expand "\e", and this way they also work
# with plain `printf '%s'`.

if type tput &>/dev/null; then
	ncolors=$(tput colors 2>/dev/null || echo 0)
fi

if [[ -n "$ncolors" ]] && [[ "$ncolors" -ge 8 ]]; then
	NC=$'\e[0m'
	BLACK=$'\e[0;30m'
	RED=$'\e[0;31m'
	GREEN=$'\e[0;32m'
	YELLOW=$'\e[0;33m'
	BLUE=$'\e[0;34m'
	MAGENTA=$'\e[0;35m'
	CYAN=$'\e[0;36m'
	WHITE=$'\e[0;37m'
	ORANGE=$'\e[38;5;208m'

	BOLD_BLACK=$'\e[1;30m'
	BOLD_RED=$'\e[1;31m'
	BOLD_GREEN=$'\e[1;32m'
	BOLD_YELLOW=$'\e[1;33m'
	BOLD_BLUE=$'\e[1;34m'
	BOLD_MAGENTA=$'\e[1;35m'
	BOLD_CYAN=$'\e[1;36m'
	BOLD_WHITE=$'\e[1;37m'
else
	NC=''
	BLACK=''
	RED=''
	GREEN=''
	YELLOW=''
	BLUE=''
	MAGENTA=''
	CYAN=''
	WHITE=''
	ORANGE=''
	BOLD_BLACK=''
	BOLD_RED=''
	BOLD_GREEN=''
	BOLD_YELLOW=''
	BOLD_BLUE=''
	BOLD_MAGENTA=''
	BOLD_CYAN=''
	BOLD_WHITE=''
fi
unset ncolors
