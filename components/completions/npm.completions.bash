# shellcheck shell=bash

cite about-completion
about-completion 'NPM (Node Package Manager) completion'

# _binary_exists (not _command_exists): the nvm plugin's lazy-load stub is a
# function named npm, and calling it here would load nvm at every shell start
if _binary_exists npm && npm_completion=$(npm completion 2> /dev/null); then
  eval "$npm_completion"
fi
unset npm_completion
