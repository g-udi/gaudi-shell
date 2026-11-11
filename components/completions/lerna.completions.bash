# shellcheck shell=bash

cite about-completion
about-completion 'Lerna bash completions'

_lerna_completions () {
  local cur compls

  # Checked here and not when this file loads: lerna often comes from a node
  # version manager that is only loaded on first use
  hash lerna 2> /dev/null || return 0

  # The currently-being-completed word.
  cur="${COMP_WORDS[COMP_CWORD]}"

  # Options
  compls="add-caching changed clean create diff exec   \
          import info init list publish repair run     \
          watch version                                \
           --loglevel --concurrency --reject-cycles    \
           --progress --sort --no-sort --help          \
           --version"

  # Tell complete what stuff to show.
  COMPREPLY=($(compgen -W "$compls" -- "$cur"))
}
complete -o default -F _lerna_completions lerna
