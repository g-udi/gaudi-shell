# shellcheck shell=bash
cite about-completion
about-completion "GitHub CLI completion"

_binary_exists gh || return 0

# Don't handle completion if it's already managed
complete -p gh &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_gh() {
  local spec
  spec="$(complete -p gh 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r gh
    eval "$(gh completion --shell=bash 2> /dev/null)"
    spec="$(complete -p gh 2> /dev/null)"
    # Completing gh itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == gh && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of gh: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_gh gh
