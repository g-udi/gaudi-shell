# shellcheck shell=bash

cite about-completion
about-completion 'Composer completion'

_binary_exists composer || return 0

# Don't handle completion if it's already managed
complete -p composer &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_composer() {
  local spec
  spec="$(complete -p composer 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r composer
    eval "$(composer completion bash 2> /dev/null)"
    spec="$(complete -p composer 2> /dev/null)"
    # Completing composer itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == composer && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of composer: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_composer composer
