# shellcheck shell=bash

cite about-completion
about-completion 'NVM (Node Version Manager) bash completions'

if [[ -n "${NVM_DIR:-}" ]] && [[ -r "$NVM_DIR"/bash_completion ]];
then
  # shellcheck source=/dev/null
  . "$NVM_DIR"/bash_completion
fi
