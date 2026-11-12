#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2128,SC1090,SC2154

# Check if command exists in $PATH
# USAGE:
#   gaudi::exists <command>
gaudi::exists () {
  command -v "$1" > /dev/null 2>&1
}

# Print the path of the program <command> on $PATH. Shell functions, aliases
# and builtins do not count, so a lazy-load stub (the nvm plugin defines
# node, npm, ... as functions) is never mistaken for the program.
# USAGE:
#   gaudi::binary <command>
gaudi::binary () {
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    whence -p -- "$1"
  else
    type -P "$1"
  fi
}

# Check if function is defined
# USAGE:
#   gaudi::defined <function>
gaudi::defined () {
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    (( ${+functions[$1]} ))
  else
    type -t "$1" &> /dev/null
  fi
}

# Check if the current directory has an entry with one of the given extensions
# (hidden entries do not count). A glob, so no process is started.
# USAGE:
#   gaudi::has_files <extension>...
gaudi::has_files () {
  # Leave a pattern without matches as it is instead of raising an error
  [[ -n "${ZSH_VERSION:-}" ]] && setopt local_options no_nomatch
  local extension entry
  for extension in "$@"; do
    for entry in ./*."$extension"; do
      [[ -e "$entry" || -L "$entry" ]] && return 0
    done
  done
  return 1
}

# Sanitize a prompt string for zsh.
# 1. Escapes literal % → %% (so zsh doesn't interpret them as prompt escapes)
# 2. Wraps ALL raw ANSI escape sequences with %{...%} (so zsh knows they are
#    zero-width and doesn't miscount the visible prompt length)
# This must be applied ONCE to the final assembled prompt, not per-segment,
# because segments like battstat embed raw ANSI codes in content.
# USAGE:
#   gaudi::zsh_sanitize_prompt <string>
gaudi::zsh_sanitize_prompt () {
  [[ -z "${ZSH_VERSION:-}" ]] && { printf '%s' "$1"; return; }
  local input="$1"
  # Step 1: Escape all literal % to %% (ANSI codes don't contain %)
  input="${input//[%]/%%}"
  # Step 2: Wrap ANSI CSI sequences (ESC[...letter) and charset sequences (ESC(letter)
  printf '%s' "$input" | sed $'s/\x1b\\[[0-9;]*[a-zA-Z]/%{&%}/g; s/\x1b([A-Z]/%{&%}/g'
}

# Draw prompt section
# USAGE:
#   gaudi::section <color> [prefix] [symbol] <content> [suffix]
gaudi::section () {

    local color prefix symbol content suffix

    [[ -n $1 ]] && color="$1"    || color=""
    [[ -n $2 ]] && prefix="$2"   || prefix=""
    [[ -n $3 ]] && symbol="$3"   || symbol=""
    [[ -n $4 ]] && content="$4"  || content=""
    [[ -n $5 ]] && suffix="$5"   || suffix=""

    if [[ $GAUDI_ENABLE_SYMBOLS == false ]]; then
      symbol="$GAUDI_SYMBOL_ALT"
    fi
    [[ -n $symbol ]] && symbol="$symbol "

    # Output raw ANSI for both shells. In zsh, gaudi::zsh_sanitize_prompt
    # post-processes the entire prompt to add %{...%} wrapping.
    printf '%s' "$color"     # Coloring (font_color + background_color)
    printf '%s' "$prefix"    # Prefix before content (default: space)
    printf '%b' "$symbol"    # Symbol/icon (%b interprets \uXXXX codes)
    printf '%s' "$content"   # Actual content to display
    printf '%s' "$suffix"    # Suffix after content
    printf '%s' "$GAUDI_NC"  # Reset coloring
}

# Load a segment definition once per shell session.
# Must run in the shell that owns the prompt (not inside $(...)) for the
# "loaded" flag to stick: gaudi::load_segments takes care of that.
# USAGE:
#   gaudi::load_segment <segment>
gaudi::load_segment () {
  local segment="$1"
  local loaded_var="GAUDI_SEGMENT_LOADED_${segment//[^a-zA-Z0-9_]/_}"
  local _loaded=0

  eval "_loaded=\${${loaded_var}:-0}"
  [[ "$_loaded" == 1 ]] && return 0

  source "$GAUDI_ROOT/segments/$segment.bash" || return 1
  eval "${loaded_var}=1"
}

# Load every segment named in GAUDI_PROMPT_LEFT/RIGHT/ASYNC, once.
# Called from gaudi::init and at the top of gaudi::prompt; it returns
# immediately unless the arrays changed since the last call, so the per-prompt
# path never re-sources segment files.
# USAGE:
#   gaudi::load_segments
gaudi::load_segments () {
  local _signature="${GAUDI_PROMPT_LEFT[*]:-}|${GAUDI_PROMPT_RIGHT[*]:-}|${GAUDI_PROMPT_ASYNC[*]:-}"
  [[ "$_signature" == "${_GAUDI_SEGMENTS_SIGNATURE:-}" ]] && return 0

  local _segment
  for _segment in ${GAUDI_PROMPT_LEFT[@]+"${GAUDI_PROMPT_LEFT[@]}"} \
    ${GAUDI_PROMPT_RIGHT[@]+"${GAUDI_PROMPT_RIGHT[@]}"} \
    ${GAUDI_PROMPT_ASYNC[@]+"${GAUDI_PROMPT_ASYNC[@]}"}; do
    gaudi::load_segment "$_segment"
  done
  _GAUDI_SEGMENTS_SIGNATURE="$_signature"
}

# Render a prompt section by getting the segments from the segments definitions array
# USAGE:
#   gaudi::render_prompt segments <array>
gaudi::render_prompt () {
  local _prompt=""
  local info=""
  local segment=""
  local segment_function=""
  local GAUDI_SYMBOL_ALT=""
  # shellcheck disable=SC2124
  local _arr_name="${1%"[@]"}"
  eval "local _segments=(\"\${${_arr_name}[@]}\")"
  if [[ -n "${_segments[*]:-}" ]]; then
    for segment in "${_segments[@]}"; do
      # Already loaded by gaudi::load_segments; this is only a fallback for
      # callers that render without going through gaudi::prompt.
      gaudi::load_segment "$segment" || continue
      segment_function="gaudi_${segment}"
      gaudi::defined "$segment_function" || continue

      GAUDI_SYMBOL_ALT="$segment"
      info="$("$segment_function")"
      [[ -n "${info}" ]] && _prompt+="$info"
    done
    printf "%s" "$_prompt"
  fi;
}

# Check usage of bash-preexec
# USAGE:
#   gaudi::check_precmd_conflict <command>
gaudi::check_precmd_conflict () {
    local f
    for f in "${precmd_functions[@]}"; do
        if [[ "${f}" == "${1}" ]]; then
            return 0
        fi
    done
    return 1
}
