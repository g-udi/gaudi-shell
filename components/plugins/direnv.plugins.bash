# shellcheck shell=bash

cite about-plugin
about-plugin 'Load direnv, if you are using it: https://direnv.net/'

[[ -x "$(which direnv)" ]] && eval "$(direnv hook bash)"
