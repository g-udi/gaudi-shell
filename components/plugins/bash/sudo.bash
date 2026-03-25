#!/usr/bin/env bash
# shellcheck shell=bash
#
# sudo — press ESC-ESC to toggle sudo at the beginning of the current command
# Bash-specific (uses READLINE_LINE)

sudo-command-line() {
    [[ ${#READLINE_LINE} -eq 0 ]] && READLINE_LINE=$(fc -l -n -1 | xargs)
    if [[ $READLINE_LINE == sudo\ * ]]; then
        READLINE_LINE="${READLINE_LINE#sudo }"
    else
        READLINE_LINE="sudo $READLINE_LINE"
    fi
    READLINE_POINT=${#READLINE_LINE}
}

if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
    bind -x '"\e\e": sudo-command-line'
fi
