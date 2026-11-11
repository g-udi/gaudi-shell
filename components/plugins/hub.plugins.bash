# shellcheck shell=bash

cite about-plugin
about-plugin 'Load GitHub support to git on the command-line via hub'

if command -v hub &> /dev/null; then
  eval "$(hub alias -s)"
fi
