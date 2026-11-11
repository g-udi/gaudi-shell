# shellcheck shell=bash

cite about-completion
about-completion 'Vault bash completion'

_binary_exists vault || return 0

# Don't handle completion if it's already managed
complete -p vault &> /dev/null && return 0

# vault completes itself
complete -C vault vault
