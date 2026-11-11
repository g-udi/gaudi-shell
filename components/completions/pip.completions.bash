# shellcheck shell=bash

cite about-completion
about-completion 'Python pip package manager bash completions'

# pip prints its own completion script
for _gaudi_pip in pip pip3; do
  _binary_exists "$_gaudi_pip" || continue
  complete -p "$_gaudi_pip" &> /dev/null && continue
  case $_gaudi_pip in
    pip) _gaudi_pip_lazy=1 ;;
    pip3) _gaudi_pip3_lazy=1 ;;
  esac
done
unset _gaudi_pip

if [[ -n "${_gaudi_pip_lazy:-}" ]]; then
  # Loaded on the first TAB, so nothing forks at shell start
  _gaudi_lazy_completion_pip() {
    local spec
    spec="$(complete -p pip 2> /dev/null)"
    if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
      complete -r pip
      eval "$(pip completion --bash 2> /dev/null)"
      spec="$(complete -p pip 2> /dev/null)"
      # Completing pip itself: 124 makes bash retry with the completion just loaded
      [[ "${1:-}" == pip && -n "$spec" ]] && return 124
    fi
    # Reached through an alias of pip: hand over to the loaded completion function
    [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
  }
  complete -F _gaudi_lazy_completion_pip pip
fi

if [[ -n "${_gaudi_pip3_lazy:-}" ]]; then
  # Loaded on the first TAB, so nothing forks at shell start
  _gaudi_lazy_completion_pip3() {
    local spec
    spec="$(complete -p pip3 2> /dev/null)"
    if [[ "$spec" == *" -F ${FUNCNAME[0]} "* ]]; then
      complete -r pip3
      eval "$(pip3 completion --bash 2> /dev/null)"
      spec="$(complete -p pip3 2> /dev/null)"
      # Completing pip3 itself: 124 makes bash retry with the completion just loaded
      [[ "${1:-}" == pip3 && -n "$spec" ]] && return 124
    fi
    # Reached through an alias of pip3: hand over to the loaded completion function
    [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]] && "${BASH_REMATCH[1]}" "$@"
  }
  complete -F _gaudi_lazy_completion_pip3 pip3
fi
unset _gaudi_pip_lazy _gaudi_pip3_lazy
