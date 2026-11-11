# shellcheck shell=bash

cite about-completion
about-completion 'Travis bash completions'

if command -v travis > /dev/null 2>&1; then
  __TRAVIS_COMPLETION_SCRIPT="${TRAVIS_CONFIG_PATH:-${HOME}/.travis}/travis.sh"
  if [[ -f "${__TRAVIS_COMPLETION_SCRIPT}" ]]; then
    # shellcheck source=/dev/null
    source "${__TRAVIS_COMPLETION_SCRIPT}"
  fi
  unset __TRAVIS_COMPLETION_SCRIPT
fi
