
# shellcheck shell=bash

cite about-completion
about-completion 'Gem bash completions'

_binary_exists gem || return 0

# gem install completes local .gem files only: listing every remote gem meant a
# full download of the index on the first TAB
_installcomp () {
  local cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=( $(compgen -f -X '!*.gem' -- "$cur") )
}

_uninstallcomp () {
  if [[ -z "$LOCAL_GEMS" ]]
  then
    LOCAL_GEMS=( $(gem list --no-versions | sed 's/\*\*\* LOCAL GEMS \*\*\*//' | tr '\n' ' ') )
  fi
  local cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=( $(compgen -W "${LOCAL_GEMS[*]}" -- $cur) )
}

_gem () {
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  case $prev in
    install)
      _installcomp
      return 0
      ;;
    uninstall)
      _uninstallcomp
      return 0
      ;;
  esac
  local commands=(build cert check cleanup contents dependency environment fetch generate_index help install list lock outdated owner pristine push query rdoc search server sources specification stale uninstall unpack update which)
  COMPREPLY=( $(compgen -W "${commands[*]}" -- $cur) )
}

complete -F _gem gem
