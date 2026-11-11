# shellcheck shell=bash

cite about-plugin
about-plugin 'Ruby Version Manager via rbenv'

export RBENV_ROOT="${RBENV_ROOT:-$HOME/.rbenv}"
pathmunge "$RBENV_ROOT/bin"

if command -v rbenv > /dev/null 2>&1; then
  eval "$(rbenv init - bash)"
fi
