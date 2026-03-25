# shellcheck shell=bash

cite about-plugin
about-plugin 'Load GitHub support to git on the command-line via hub'

command -v hub &> /dev/null && eval "$(hub alias -s)"
