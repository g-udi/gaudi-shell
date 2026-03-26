# shellcheck shell=bash

cite about-completion
about-completion 'NVM (Node Version Manager) bash completions'

if [[ "$NVM_DIR" ]] && [[ -r "$NVM_DIR"/bash_completion ]];
then
  . "$NVM_DIR"/bash_completion
fi
