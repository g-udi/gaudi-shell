# shellcheck shell=bash

cite about-completion
about-completion 'Packer bash completions'

_binary_exists packer || return 0

# Don't handle completion if it's already managed
complete -p packer &> /dev/null && return 0

# packer completes itself
complete -C packer packer
