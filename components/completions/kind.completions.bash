# shellcheck shell=bash
cite about-completion
about-completion "kind (Kubernetes IN Docker) completion"

_binary_exists kind || return 0

# Don't handle completion if it's already managed
complete -p kind &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_kind() {
  local spec
  spec="$(complete -p kind 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r kind
    eval "$(kind completion bash 2> /dev/null)"
    spec="$(complete -p kind 2> /dev/null)"
    # Completing kind itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == kind && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of kind: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_kind kind
