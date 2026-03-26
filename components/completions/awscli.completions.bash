# shellcheck shell=bash

cite about-completion
about-completion 'AWS CLI completions'

[[ -x "$(which aws_completer)" ]] && complete -C "$(which aws_completer)" aws
