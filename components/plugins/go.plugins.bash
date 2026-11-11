# shellcheck shell=bash

cite about-plugin
about-plugin 'Go environment variables & path configuration'

command -v go &>/dev/null || return 0

_go_pathmunge_wrap () {
  # Plain parameter expansion, no arrays, so it behaves the same in bash
  # (3.2 included) and zsh. The list is walked from its last entry to its
  # first, so that prepending keeps the order in which the paths were given
  local rest="$1" dir
  while [[ -n "$rest" ]]; do
    dir="${rest##*:}"
    if [[ "$rest" == *:* ]]; then
      rest="${rest%:*}"
    else
      rest=""
    fi
    if [[ -n "$dir" ]]; then
      pathmunge "${dir}/bin"
    fi
  done
}

export GOROOT="${GOROOT:-$(go env GOROOT)}"
export GOPATH="${GOPATH:-$(go env GOPATH)}"
_go_pathmunge_wrap "${GOPATH}:${GOROOT}"
