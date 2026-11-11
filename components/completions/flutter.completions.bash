# shellcheck shell=bash

cite about-completion
about-completion 'Flutter bash completions'

_binary_exists flutter || return 0

# Don't handle completion if it's already managed
complete -p flutter &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_flutter() {
  local spec
  spec="$(complete -p flutter 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r flutter
    eval "$(flutter bash-completion 2> /dev/null)"
    spec="$(complete -p flutter 2> /dev/null)"
    # Completing flutter itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == flutter && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of flutter: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_flutter flutter
