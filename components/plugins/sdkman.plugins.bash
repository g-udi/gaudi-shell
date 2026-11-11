# shellcheck shell=bash

cite about-plugin
about-plugin 'Load Software Development Kit Manager'

# Use $SDKMAN_DIR if defined, otherwise default to ~/.sdkman
export SDKMAN_DIR=${SDKMAN_DIR:-$HOME/.sdkman}

if [[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]]; then
  # shellcheck source=/dev/null
  source "${SDKMAN_DIR}/bin/sdkman-init.sh"
fi
