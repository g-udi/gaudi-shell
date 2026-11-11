# shellcheck shell=bash
cite about-completion
about-completion "cargo (Rust package manager) completion"

_binary_exists rustup || return 0
_binary_exists cargo || return 0

# Don't handle completion if it's already managed
complete -p cargo &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_cargo() {
  local spec
  spec="$(complete -p cargo 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r cargo
    eval "$(rustup completions bash cargo 2> /dev/null)"
    spec="$(complete -p cargo 2> /dev/null)"
    # Completing cargo itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == cargo && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of cargo: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_cargo cargo
