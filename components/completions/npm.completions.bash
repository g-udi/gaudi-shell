# shellcheck shell=bash

cite about-completion
about-completion 'NPM (Node Package Manager) completion'

# Only a real npm binary counts: the nvm plugin's lazy-load stub is a function
# named npm, and calling it here would load nvm at every shell start
if (unset -f npm 2>/dev/null; command -v npm) &>/dev/null
then
  eval "$(npm completion)"
fi
