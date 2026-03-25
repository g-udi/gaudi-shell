
# shellcheck shell=bash

cite about-completion
about-completion 'Terraform bash completions'

# Make sure terraform is installed
_command_exists terraform || return

# Don't handle completion if it's already managed
complete -p terraform &>/dev/null && return

# Terraform completes itself
complete -C terraform terraform
