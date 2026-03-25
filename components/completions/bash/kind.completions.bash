# shellcheck shell=bash
cite about-completion
about-completion "kind (Kubernetes IN Docker) completion"

# Make sure kind is installed
_command_exists kind || return

# Don't handle completion if it's already managed
complete -p kind &> /dev/null && return

eval "$(kind completion bash)"
