# shellcheck shell=bash

cite about-completion
about-completion 'Bash completion support for RVM'

if [[ -r "${rvm_path:-}/scripts/completion" ]]; then
  # shellcheck source=/dev/null
  . "${rvm_path}/scripts/completion"
fi
