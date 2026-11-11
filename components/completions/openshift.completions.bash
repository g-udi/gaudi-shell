# shellcheck shell=bash

cite about-completion
about-completion 'Openshift bash completions'

_binary_exists oc || return 0

# Don't handle completion if it's already managed
complete -p oc &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_oc() {
  local spec
  spec="$(complete -p oc 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r oc
    eval "$(oc completion bash 2> /dev/null)"
    spec="$(complete -p oc 2> /dev/null)"
    # Completing oc itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == oc && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of oc: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_oc oc
