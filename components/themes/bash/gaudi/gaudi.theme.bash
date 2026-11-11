#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2034

GAUDI_ROOT="${GAUDI_SHELL}/components/themes/bash/gaudi"

# Do not load if not an interactive shell.
# Reference: https://github.com/nojhan/liquidprompt/issues/161
test -z "$TERM" -o "x$TERM" = xdumb && return

source "$GAUDI_ROOT/gaudi.configs.bash"
source "$GAUDI_ROOT/lib/utils.bash"
source "$GAUDI_ROOT/lib/colors.bash"
source "$GAUDI_ROOT/lib/scm.bash"

GAUDI_THEME_SHELL_ID="${GAUDI_THEME_SHELL_ID:-$$}"
GAUDI_THEME_CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/gaudi-bash/theme/gaudi"
GAUDI_THEME_ASYNC_CACHE_DIR="${GAUDI_THEME_CACHE_ROOT}/async"
GAUDI_THEME_STATE_DIR="${GAUDI_THEME_CACHE_ROOT}/state/${GAUDI_THEME_SHELL_ID}"
GAUDI_THEME_GENERATION_FILE="${GAUDI_THEME_STATE_DIR}/generation"
GAUDI_THEME_LEFT_PROMPT_FILE="${GAUDI_THEME_STATE_DIR}/left_prompt"
GAUDI_THEME_RIGHT_PROMPT_FILE="${GAUDI_THEME_STATE_DIR}/right_prompt"

gaudi::ensure_async_dirs () {
  mkdir -p "$GAUDI_THEME_ASYNC_CACHE_DIR" "$GAUDI_THEME_STATE_DIR"
}

gaudi::write_atomic () {
  local file="$1"
  local content="$2"
  local dir="${file%/*}"
  local tmp_file=""

  mkdir -p "$dir" || return 1
  tmp_file="$(mktemp "${dir}/.gaudi.XXXXXX")" || return 1
  printf "%s" "$content" > "$tmp_file" || {
    rm -f "$tmp_file"
    return 1
  }

  mv "$tmp_file" "$file"
}

gaudi::current_generation () {
  local current_generation="0"

  if [[ -e "$GAUDI_THEME_GENERATION_FILE" ]]; then
    current_generation="$(<"$GAUDI_THEME_GENERATION_FILE")"
  fi

  printf "%s" "${current_generation:-0}"
}

gaudi::next_generation () {
  local current_generation="0"
  local next_generation="1"

  current_generation="$(gaudi::current_generation)"
  next_generation=$((current_generation + 1))
  gaudi::write_atomic "$GAUDI_THEME_GENERATION_FILE" "$next_generation" || return 1

  printf "%s" "$next_generation"
}

gaudi::store_prompt_state () {
  gaudi::write_atomic "$GAUDI_THEME_LEFT_PROMPT_FILE" "$1" || return 1
  gaudi::write_atomic "$GAUDI_THEME_RIGHT_PROMPT_FILE" "$2"
}

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
  gaudi::ensure_async_dirs
  gaudi::load_segment continuation

  PS2="$(gaudi_continuation)"
  PS4='$0.$LINENO+ '

  gaudi::register_prompt_hook
}

gaudi::prompt () {

  # Must be the very first line in all entry prompt functions, or the value
  # will be overridden by a different command execution - do not move this line!
  RETVAL=$?

  local generation=""
  local prompt_char=""
  local compensate=58
  local left_prompt=""
  local right_prompt=""
  local async_prompt=""
  local line_separator=""

  if [[ -n "${ZSH_VERSION:-}" ]]; then
    # Use zsh native prompt escapes — no %{...%} wrapping needed, cursor
    # width is always correct.
    prompt_char="%F{2}>>%f "
  else
    prompt_char="${GAUDI_GREEN}>>${NC} "
  fi

  gaudi::ensure_async_dirs
  generation="$(gaudi::next_generation)" || return 1

  left_prompt="$(gaudi::render_prompt GAUDI_PROMPT_LEFT[@])"
  right_prompt="$(gaudi::render_prompt GAUDI_PROMPT_RIGHT[@])"
  gaudi::store_prompt_state "$left_prompt" "$right_prompt"

  if [[ -n "${ZSH_VERSION:-}" ]]; then
    # In zsh, render async segments synchronously — always fresh, no stale
    # cache flash. Async redraw via tput doesn't work in zsh, and showing
    # stale-then-fresh data looks buggy (e.g., yellow then green git status).
    async_prompt="$(gaudi::render_prompt GAUDI_PROMPT_ASYNC[@])"

    left_prompt="$(gaudi::zsh_sanitize_prompt "$left_prompt")"
    right_prompt="$(gaudi::zsh_sanitize_prompt "$right_prompt")"
    async_prompt="$(gaudi::zsh_sanitize_prompt "$async_prompt")"

    PROMPT=$'\n'"${left_prompt}${async_prompt}"$'\n\n'"${prompt_char}"
    RPROMPT="${right_prompt}"
  else
    # Render async segments synchronously — always fresh, no stale cache flash.
    async_prompt="$(gaudi::render_prompt GAUDI_PROMPT_ASYNC[@])"

    if [[ $GAUDI_SPLIT_PROMPT == false ]]; then
      PS1=$(printf "\n%b%b%b\n\n%b" "$right_prompt" "$left_prompt" "$async_prompt" "$prompt_char")
    else
      [[ "$TERM" =~ screen.* ]] && compensate=45
      [[ $GAUDI_SPLIT_PROMPT_TWO_LINES == true ]] && line_separator=$'\n' || line_separator=$'\r'
      PS1=$(printf "\n%*b%b%b%b\n\n%b" "$(($(tput cols) + compensate))" "$right_prompt" "$line_separator" "$left_prompt" "$async_prompt" "$prompt_char")
    fi
  fi
}

gaudi::init
