# shellcheck shell=bash

cite about-completion
about-completion 'PM2 bash completions'

# Same model as npm's own completion: the words are re-split locally, so the
# global COMP_WORDBREAKS is left alone
_pm2_completion() {
  local words cword si="$IFS"
  if declare -F _get_comp_words_by_ref > /dev/null; then
    _get_comp_words_by_ref -n = -n @ -n : -w words -i cword
  else
    cword="$COMP_CWORD"
    words=("${COMP_WORDS[@]}")
  fi
  # shellcheck disable=SC2207
  IFS=$'\n' COMPREPLY=($(COMP_CWORD="$cword" \
    COMP_LINE="$COMP_LINE" \
    COMP_POINT="$COMP_POINT" \
    pm2 completion -- "${words[@]}" \
    2> /dev/null)) || return $?
  IFS="$si"
  if declare -F __ltrim_colon_completions > /dev/null; then
    __ltrim_colon_completions "${words[cword]}"
  fi
}
complete -o default -F _pm2_completion pm2
