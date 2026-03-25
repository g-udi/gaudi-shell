# shellcheck shell=bash
cite about-completion
about-completion "GitHub CLI completion"

# Make sure gh is installed
_binary_exists gh || return

# Don't handle completion if it's already managed
complete -p gh &> /dev/null && return

eval "$(gh completion --shell=bash)"
