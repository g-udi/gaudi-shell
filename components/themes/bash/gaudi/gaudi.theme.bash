#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016,SC2034

GAUDI_ROOT="${GAUDI_SHELL}/components/themes/bash/gaudi"

# Do not load if not an interactive shell.
# Reference: https://github.com/nojhan/liquidprompt/issues/161
test -z "$TERM" -o "x$TERM" = xdumb && return

source "$GAUDI_ROOT/gaudi.configs.bash"
source "$GAUDI_ROOT/lib/utils.bash"
source "$GAUDI_ROOT/lib/colors.bash"
source "$GAUDI_ROOT/lib/scm.bash"

gaudi::register_prompt_hook () {
  if gaudi::defined __bp_precmd_invoke_cmd; then
    gaudi::check_precmd_conflict "gaudi::prompt" || precmd_functions+=(gaudi::prompt)
    return 0
  fi

  [[ "${PROMPT_COMMAND:-}" == *"gaudi::prompt"* ]] && return 0

  if [[ -n "${PROMPT_COMMAND:-}" ]]; then
    PROMPT_COMMAND=$'gaudi::prompt\n'"$PROMPT_COMMAND"
  else
    PROMPT_COMMAND="gaudi::prompt"
  fi
}

gaudi::init () {
  gaudi::load_segment continuation

  # Source every configured segment once, in this shell. gaudi::prompt renders
  # them inside command substitutions, where a "loaded" flag would be lost.
  gaudi::load_segments

  PS2="$(gaudi_continuation)"
  PS4='$0.$LINENO+ '

  gaudi::register_prompt_hook
}

gaudi::prompt () {

  # Must be the very first line in all entry prompt functions, or the value
  # will be overridden by a different command execution - do not move this line!
  RETVAL=$?

  local compensate=58
  local left_prompt=""
  local right_prompt=""
  local async_prompt=""
  local line_separator=""

  # Cheap no-op unless the GAUDI_PROMPT_* arrays changed since the last prompt.
  gaudi::load_segments

  left_prompt="$(gaudi::render_prompt GAUDI_PROMPT_LEFT[@])"
  right_prompt="$(gaudi::render_prompt GAUDI_PROMPT_RIGHT[@])"
  # Async segments are rendered synchronously — always fresh, no stale cache
  # flash (async redraw via tput doesn't work in zsh, and stale-then-fresh data
  # looks buggy, e.g. yellow then green git status).
  async_prompt="$(gaudi::render_prompt GAUDI_PROMPT_ASYNC[@])"

  # SECURITY: rendered segment text (git branch, directory names, ...) is
  # untrusted. The shell expands the prompt string again every time it is
  # displayed, so that text must never be pasted into PS1/PROMPT where a name
  # such as $(cmd) or `cmd` would run. The rendered text is kept in
  # _GAUDI_RENDERED_* variables and the prompt string only *references* them: the
  # reference is expanded once and its value is not expanded again.
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    # gaudi::zsh_sanitize_prompt doubles every literal % (so content cannot
    # inject prompt escapes) and wraps ANSI sequences in %{...%}.
    _GAUDI_RENDERED_LEFT="$(gaudi::zsh_sanitize_prompt "${left_prompt}${async_prompt}")"
    _GAUDI_RENDERED_RIGHT="$(gaudi::zsh_sanitize_prompt "$right_prompt")"

    # The prompt character uses zsh native escapes — no %{...%} wrapping
    # needed, cursor width is always correct.
    if [[ -o promptsubst ]]; then
      # PROMPT_SUBST expands the references first, then % escapes in the result.
      PROMPT=$'\n${_GAUDI_RENDERED_LEFT}\n\n%F{2}>>%f '
      RPROMPT='${_GAUDI_RENDERED_RIGHT}'
    else
      # Without PROMPT_SUBST nothing but % escapes is expanded, so the
      # sanitized text can be embedded directly.
      PROMPT=$'\n'"${_GAUDI_RENDERED_LEFT}"$'\n\n%F{2}>>%f '
      RPROMPT="${_GAUDI_RENDERED_RIGHT}"
    fi
  else
    if [[ $GAUDI_SPLIT_PROMPT == false ]]; then
      printf -v _GAUDI_RENDERED_LINE "%b%b%b" "$right_prompt" "$left_prompt" "$async_prompt"
    else
      [[ "$TERM" =~ screen.* ]] && compensate=45
      [[ $GAUDI_SPLIT_PROMPT_TWO_LINES == true ]] && line_separator=$'\n' || line_separator=$'\r'
      printf -v _GAUDI_RENDERED_LINE "%*b%b%b%b" "$(($(tput cols) + compensate))" "$right_prompt" "$line_separator" "$left_prompt" "$async_prompt"
    fi

    # The colour escapes of the last line are wrapped in \[ \] so readline
    # does not count them as visible width.
    if shopt -q promptvars; then
      PS1='\n${_GAUDI_RENDERED_LINE}\n\n\[${GAUDI_GREEN}\]>>\[${NC}\] '
    else
      # promptvars is off: references would be shown literally, but nothing in
      # PS1 is expanded either, apart from backslash escapes — neutralise those.
      PS1="\n${_GAUDI_RENDERED_LINE//\\/\\\\}\n\n\[${GAUDI_GREEN}\]>>\[${NC}\] "
    fi
  fi
}

gaudi::init
