# shellcheck shell=bash

cite about-plugin
about-plugin 'Add mactex to the path if its present'

# /Library/TeX/texbin is the stable link MacTeX keeps to its current release
for MACTEX_PATH in /Library/TeX/texbin /usr/local/texlive/*/bin/universal-darwin; do
  if [[ -d $MACTEX_PATH ]]; then
    pathmunge "$MACTEX_PATH" after
    break
  fi
done
unset MACTEX_PATH
