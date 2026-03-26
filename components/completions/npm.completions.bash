# shellcheck shell=bash

cite about-completion
about-completion 'NPM (Node Package Manager) completion'

if command -v npm &>/dev/null
then
  eval "$(npm completion)"
fi
