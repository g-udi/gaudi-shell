# shellcheck shell=bash
cite about-completion
about-completion "cargo (Rust package manager) completion"

# Make sure cargo is installed
_command_exists rustup || return
_command_exists cargo || return

# Don't handle completion if it's already managed
complete -p cargo &> /dev/null && return

eval "$(rustup completions bash cargo)"
