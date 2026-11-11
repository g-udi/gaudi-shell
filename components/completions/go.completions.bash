# shellcheck shell=bash

cite about-completion
about-completion 'Go bash completions'

# Install gocomplete:
# go install github.com/posener/complete/gocomplete@latest
# gocomplete -install

if _command_exists gocomplete && _command_exists go ; then
  complete -C "${GOBIN}"/gocomplete go
fi
