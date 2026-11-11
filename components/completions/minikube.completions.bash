# shellcheck shell=bash

cite about-completion
about-completion 'Minikube (Local Kubernetes) completion'

_binary_exists minikube || return 0

# Don't handle completion if it's already managed
complete -p minikube &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_minikube() {
  local spec
  spec="$(complete -p minikube 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r minikube
    eval "$(minikube completion bash 2> /dev/null)"
    spec="$(complete -p minikube 2> /dev/null)"
    # Completing minikube itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == minikube && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of minikube: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_minikube minikube
