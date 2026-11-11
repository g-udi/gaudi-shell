# shellcheck shell=bash

cite about-completion
about-completion 'Gulp bash completions'

_gulp_completions () {
    # The currently-being-completed word.
    local cur="${COMP_WORDS[COMP_CWORD]}"
    # Checked here and not when this file loads: gulp often comes from a node
    # version manager that is only loaded on first use
    hash gulp 2> /dev/null || return 0
    #Grab tasks
    local compls=$(gulp --tasks-simple 2> /dev/null)
    # Tell complete what stuff to show.
    COMPREPLY=($(compgen -W "$compls" -- "$cur"))
}
complete -o default -F _gulp_completions gulp
