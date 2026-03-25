# shellcheck shell=bash

cite about-completion
about-completion 'Gaudi bash completions'

_gaudi-shell-comp-list-available-not-enabled () {
  subdirectory="$1"

  local available_things

  available_things=$(for f in $(compgen -G "${GAUDI_SHELL}/components/$subdirectory/lib/*.bash" | sort -d);
    do
      file_entity=$(basename "$f")
      local enabled_components
      enabled_components=$(command ls "${GAUDI_SHELL}/components/enabled/"[0-9]*$GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR$file_entity 2>/dev/null | head -1)

      if [[ -z "$enabled_components" ]]
      then
        basename $f | sed -e 's/\(.*\)\..*\.bash/\1/g'
      fi
    done)

  COMPREPLY=( $(compgen -W "all ${available_things}" -- ${CURRENT}) )
}

_gaudi-shell-comp-list-enabled () {
  local subdirectory="$1"
  local enabled_things

  enabled_things=$(for f in $(sort -d <(compgen -G "${GAUDI_SHELL}/components/enabled/*.$subdirectory.bash") <(compgen -G "${GAUDI_SHELL}/components/enabled/*.$subdirectory.bash"));
    do
      basename "$f" | sed -e 's/\(.*\)\..*\.bash/\1/g' | sed -e "s/^[0-9]*___//g"
    done)

  COMPREPLY=( $(compgen -W "all ${enabled_things}" -- ${CURRENT}) )
}

_gaudi-shell-comp-list-available () {
  subdirectory="$1"

  local enabled_things

  enabled_things=$(for f in $(compgen -G "${GAUDI_SHELL}/components/$subdirectory/lib/*.bash" | sort -d);
    do
      basename $f | sed -e 's/\(.*\)\..*\.bash/\1/g'
    done)

  COMPREPLY=( $(compgen -W "${enabled_things}" -- ${CURRENT}) )
}

_gaudi-shell-comp () {
  
  local BASE_OPTIONS="show enable disable reload restart search update backup doctor help version"
  local CURRENT PREVIOUS

  COMPREPLY=()
  CURRENT="${COMP_WORDS[COMP_CWORD]}"
  PREVIOUS="${COMP_WORDS[COMP_CWORD - 1]}"
  
  verb="${COMP_WORDS[1]}"
  file_type="${COMP_WORDS[2]}"
  
  case "${verb}" in
    show)
			local show_args="aliases completions plugins"
			COMPREPLY=( $(compgen -W "${show_args}" -- ${CURRENT}) )
      return 0
			;;
    help)
      if [[ x"${PREVIOUS}" == x"aliases" ]]; then
        _gaudi-shell-comp-list-available aliases
        return 0
      else
        local help_args="aliases completions plugins"
        COMPREPLY=( $(compgen -W "${help_args}" -- ${CURRENT}) )
        return 0
      fi
      ;;
    doctor)
      local doctor_args="errors warnings all"
      COMPREPLY=( $(compgen -W "${doctor_args}" -- ${CURRENT}) )
      return 0
      ;;
     reload | search | update | version)
      return 0
      ;;
    enable | disable)
      if [[ x"${verb}" == x"enable" ]];then
        suffix="available-not-enabled"
      else
        suffix="enabled"
      fi
      case "${file_type}" in
        alias)
            _gaudi-shell-comp-list-${suffix} aliases
            return 0
            ;;
        plugin)
            _gaudi-shell-comp-list-${suffix} plugins
            return 0
            ;;
        completion)
            _gaudi-shell-comp-list-${suffix} completions
            return 0
            ;;
        *)
            local enable_disable_args="alias completion plugin"
            COMPREPLY=( $(compgen -W "${enable_disable_args}" -- ${CURRENT}) )
            return 0
            ;;
      esac
      ;;
  esac

  COMPREPLY=( $(compgen -W "${BASE_OPTIONS}" -- ${CURRENT}) )

  return 0
}

# Activate completion for gaudi-shell and its common misspellings
complete -F _gaudi-shell-comp gaudi-shell
complete -F _gaudi-shell-comp gudi-bash