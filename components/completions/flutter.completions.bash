# shellcheck shell=bash

cite about-completion
about-completion 'Flutter bash completions'

if _command_exists flutter; then
  eval "$(flutter bash-completion)"
fi
