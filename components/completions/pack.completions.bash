# shellcheck shell=bash

cite about-completion
about-completion 'pack (Cloud Native Buildpacks CLI) completion'

_binary_exists pack || return 0

# Don't handle completion if it's already managed
complete -p pack &> /dev/null && return 0

# "pack completion" writes its script to a file and prints the path
# Loaded on the first TAB, so nothing forks at shell start
_gaudi_lazy_completion_pack() {
  local spec
  spec="$(complete -p pack 2> /dev/null)"
  if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
    complete -r pack
    # shellcheck source=/dev/null
    source "$(pack completion --shell bash 2> /dev/null)" 2> /dev/null
    spec="$(complete -p pack 2> /dev/null)"
    # Completing pack itself: 124 makes bash retry with the completion just loaded
    [[ "${1:-}" == pack && -n "$spec" ]] && return 124
  fi
  # Reached through an alias of pack: hand over to the loaded completion function
  [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
}
complete -F _gaudi_lazy_completion_pack pack
