# shellcheck shell=bash

cite about-completion
about-completion 'Fabric bash completions'

# Fabric 2+ prints its own completion script
_binary_exists fab || return 0

# Don't handle completion if it's already managed
complete -p fab &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_fab() {
  local spec
  spec="$(complete -p fab 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r fab
    eval "$(fab --print-completion-script bash 2> /dev/null)"
    spec="$(complete -p fab 2> /dev/null)"
    # Completing fab itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == fab && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of fab: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_fab fab
