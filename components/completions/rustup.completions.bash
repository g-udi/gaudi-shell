# shellcheck shell=bash
cite about-completion
about-completion "rustup (Rust toolchain installer) completion"

_binary_exists rustup || return 0

# Don't handle completion if it's already managed
complete -p rustup &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_rustup() {
  local spec
  spec="$(complete -p rustup 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r rustup
    eval "$(rustup completions bash 2> /dev/null)"
    spec="$(complete -p rustup 2> /dev/null)"
    # Completing rustup itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == rustup && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of rustup: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_rustup rustup
