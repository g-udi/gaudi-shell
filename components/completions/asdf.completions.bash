# shellcheck shell=bash

cite about-completion
about-completion 'asdf completions | The multiple runtime version manager'

_binary_exists asdf || return 0

# Don't handle completion if it's already managed
complete -p asdf &> /dev/null && return 0

# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_asdf() {
  local spec
  spec="$(complete -p asdf 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r asdf
    eval "$(asdf completion bash 2> /dev/null)"
    spec="$(complete -p asdf 2> /dev/null)"
    # Completing asdf itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == asdf && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of asdf: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_asdf asdf
