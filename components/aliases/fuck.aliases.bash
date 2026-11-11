# shellcheck shell=bash

cite about-alias
about-alias 'fuck/please to retry last command with sudo'

if ! _binary_exists fuck; then
  # Re-run the previous command with sudo: show it and ask before running it
  fuck() {
    local last answer
    last="$(fc -ln -1)"
    last="${last#"${last%%[![:space:]]*}"}"
    if [[ -z "$last" ]]; then
      echo "fuck: no previous command found" >&2
      return 1
    fi
    printf 'sudo %s\nRun this with sudo? [y/N] ' "$last"
    read -r answer
    case "$answer" in
      [yY] | [yY][eE][sS]) eval "sudo $last" ;;
      *) return 1 ;;
    esac
  }
fi
alias please=fuck
alias plz=please
alias fucking=sudo
