# shellcheck shell=bash

cite about-completion
about-completion 'AWS CLI completions'

if aws_completer=$(command -v aws_completer); then
  complete -C "$aws_completer" aws
fi
unset aws_completer
