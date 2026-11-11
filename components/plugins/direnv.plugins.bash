# shellcheck shell=bash

cite about-plugin
about-plugin 'Load direnv, if you are using it: https://direnv.net/'

if command -v direnv > /dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi
