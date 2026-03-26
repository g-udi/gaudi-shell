# shellcheck shell=bash
cite about-completion
about-completion "rustup (Rust toolchain installer) completion"

# Make sure rustup is installed
_command_exists rustup || return

# Don't handle completion if it's already managed
complete -p rustup &> /dev/null && return

eval "$(rustup completions bash)"
