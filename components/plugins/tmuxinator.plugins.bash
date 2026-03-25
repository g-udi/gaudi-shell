# shellcheck shell=bash
# shellcheck disable=SC1090

cite about-plugin
about-plugin 'Sources tmuxinator script if available'

[[ -s "$HOME/.tmuxinator/scripts/tmuxinator" ]] && . "$HOME/.tmuxinator/scripts/tmuxinator"
