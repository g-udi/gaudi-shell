# shellcheck shell=bash

cite about-completion
about-completion 'Helm (Kubernetes Package Manager) completions'

_binary_exists helm || return 0

# Don't handle completion if it's already managed
complete -p helm &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_helm() {
  local spec
  spec="$(complete -p helm 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r helm
    eval "$(helm completion bash 2> /dev/null)"
    spec="$(complete -p helm 2> /dev/null)"
    # Completing helm itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == helm && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of helm: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_helm helm
