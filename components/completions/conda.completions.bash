
# shellcheck shell=bash

cite about-completion
about-completion 'Enable Conda completions'

if register_python_argcomplete=$(command -v register-python-argcomplete); then
  eval "$("$register_python_argcomplete" conda)"
fi
unset register_python_argcomplete
