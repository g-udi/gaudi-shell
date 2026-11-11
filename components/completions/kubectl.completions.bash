# shellcheck shell=bash

cite about-completion
about-completion 'Kubectl (Kubernetes CLI) completion'

_binary_exists kubectl || return 0

# Don't handle completion if it's already managed
complete -p kubectl &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_kubectl() {
  local spec
  spec="$(complete -p kubectl 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r kubectl
    eval "$(kubectl completion bash 2> /dev/null)"
    spec="$(complete -p kubectl 2> /dev/null)"
    # Completing kubectl itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == kubectl && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of kubectl: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_kubectl kubectl
