
# shellcheck shell=bash

cite about-completion
about-completion 'Enable Conda completions'

_command_exists argcomplete && which register-python-argcomplete > /dev/null \
  && eval "$(register-python-argcomplete conda)"
