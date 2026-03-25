# shellcheck shell=bash

cite about-plugin
about-plugin 'Add mactex to the path if its present'

MACTEX_PATH=/usr/local/texlive/2009/bin/universal-darwin
if [[ -d  $MACTEX_PATH ]]; then
  pathmunge $MACTEX_PATH after
fi
unset MACTEX_PATH
