#!/usr/bin/env bash
# shellcheck shell=bash

# Colours of the theme, as literal ANSI sequences: the same bytes `tput` prints
# on a 256-colour terminal, without starting a process for each of them.

# Reset, under the theme's own name: NC belongs to the framework (lib/colors.bash)
# and keeps its value. The split bash prompt pads the right-hand side by a fixed number of
# invisible bytes, so this stays the exact sequence `tput sgr0` gives: screen
# and tmux terminals use a different one from xterm-like terminals.
case "${TERM:-}" in
  screen* | tmux*) export GAUDI_NC=$'\e[m\017' ;;
  *) export GAUDI_NC=$'\e(B\e[m' ;;
esac

# Regular Colors
export GAUDI_BLACK=$'\e[30m'
export GAUDI_RED=$'\e[31m'
export GAUDI_GREEN=$'\e[32m'
export GAUDI_YELLOW=$'\e[33m'
export GAUDI_BLUE=$'\e[34m'
export GAUDI_MAGENTA=$'\e[38;5;165m'
export GAUDI_CYAN=$'\e[36m'
export GAUDI_WHITE=$'\e[97m'
export GAUDI_ORANGE=$'\e[38;5;202m'

# Background
export BACKGROUND_GAUDI_BLACK=$'\e[40m'
export BACKGROUND_GAUDI_RED=$'\e[41m'
export BACKGROUND_GAUDI_GREEN=$'\e[42m'
export BACKGROUND_GAUDI_YELLOW=$'\e[43m'
export BACKGROUND_GAUDI_BLUE=$'\e[44m'
export BACKGROUND_GAUDI_MAGENTA=$'\e[45m'
export BACKGROUND_GAUDI_CYAN=$'\e[46m'
export BACKGROUND_GAUDI_WHITE=$'\e[107m'
export BACKGROUND_GAUDI_ORANGE=$'\e[48;5;202m'
