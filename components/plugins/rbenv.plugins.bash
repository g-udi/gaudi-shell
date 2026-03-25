# shellcheck shell=bash

cite about-plugin
about-plugin 'Ruby Version Manager via rbenv'

export RBENV_ROOT="$HOME/.rbenv"
pathmunge "$RBENV_ROOT/bin"

[[ `which rbenv 2>/dev/null` ]] && eval "$(rbenv init - bash)"
