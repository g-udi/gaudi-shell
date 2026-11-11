
# shellcheck shell=bash

cite about-completion
about-completion 'Bash completion support for SSH'

_sshcomplete () {
    # Take the current word with ":" kept, instead of removing ":" from the global COMP_WORDBREAKS
    local CURRENT_PROMPT
    if declare -F _get_comp_words_by_ref > /dev/null; then
        _get_comp_words_by_ref -n : -c CURRENT_PROMPT
    else
        CURRENT_PROMPT="${COMP_WORDS[COMP_CWORD]}"
    fi
    if [[ ${CURRENT_PROMPT} == *@*  ]] ; then
      local OPTIONS="-P ${CURRENT_PROMPT/@*/}@ -- ${CURRENT_PROMPT/*@/}"
    else
      local OPTIONS=" -- ${CURRENT_PROMPT}"
    fi

    # parse all defined hosts from .ssh/config and files included there
    for fl in "$HOME/.ssh/config" \
        $(grep "^\s*Include" "$HOME/.ssh/config" |
            awk '{for (i=2; i<=NF; i++) print $i}' |
            sed -Ee "s|^([^/~])|$HOME/.ssh/\1|" -e "s|^~/|$HOME/|")
    do
        if [[ -r "$fl" ]]; then
            COMPREPLY=( ${COMPREPLY[@]} $(compgen -W "$(grep -i ^Host "$fl" |grep -v '[*!]' | awk '{for (i=2; i<=NF; i++) print $i}' )" ${OPTIONS}) )
        fi
    done

    # parse all hosts found in .ssh/known_hosts
    if [[ -r "$HOME/.ssh/known_hosts" ]]; then
        if grep -v -q -e '^ ssh-rsa' "$HOME/.ssh/known_hosts" ; then
            COMPREPLY=( ${COMPREPLY[@]} $(compgen -W "$( awk '{print $1}' "$HOME/.ssh/known_hosts" | grep -v ^\| | cut -d, -f 1 | sed -e 's/\[//g' | sed -e 's/\]//g' | cut -d: -f1 | grep -v ssh-rsa)" ${OPTIONS}) )
        fi
    fi

    # parse hosts defined in /etc/hosts
    if [[ -r /etc/hosts ]]; then
        COMPREPLY=( ${COMPREPLY[@]} $(compgen -W "$( grep -v '^[[:space:]]*$' /etc/hosts | grep -v '^#' | awk '{for (i=2; i<=NF; i++) print $i}' )" ${OPTIONS}) )
    fi

    declare -F __ltrim_colon_completions > /dev/null && __ltrim_colon_completions "$CURRENT_PROMPT"
    return 0
}

complete -o default -o nospace -F _sshcomplete ssh scp slogin sftp
