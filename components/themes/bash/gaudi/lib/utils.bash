#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2128,SC1090,SC2154

# Check if command exists in $PATH
# USAGE:
#   gaudi::exists <command>
gaudi::exists () {
  command -v "$1" > /dev/null 2>&1
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
    printf '%s' "$NC"        # Reset coloring
}

# Load a segment definition once per shell session.
# USAGE:
#   gaudi::load_segment <segment>
gaudi::load_segment () {
  local segment="$1"
  local loaded_var="GAUDI_SEGMENT_LOADED_$(echo "$segment" | tr -c 'a-zA-Z0-9_' '_')"

  eval "local _loaded=\${${loaded_var}:-0}"
  [[ "$_loaded" == 1 ]] && return 0

  source "$GAUDI_ROOT/segments/$segment.bash" || return 1
  eval "${loaded_var}=1"
}

# Render a single segment by name.
# USAGE:
#   gaudi::render_segment <segment>
gaudi::render_segment () {
  local segment="$1"
  local segment_function="gaudi_${segment}"
  local info=""
  local GAUDI_SYMBOL_ALT="$segment"

  gaudi::load_segment "$segment" || return 1
  gaudi::defined "$segment_function" || return 1

  info="$("$segment_function")"
  [[ -n $info ]] && printf "%s" "$info"
}

# Render a prompt section by getting the segments from the segments definitions array
# USAGE:
#   gaudi::render_prompt segments <array>
gaudi::render_prompt () {
  local _prompt=""
  local info=""
  local _arr_name="${1%"[@]"}"
  eval "local _segments=(\"\${${_arr_name}[@]}\")"
  if [[ -n "${_segments[*]:-}" ]]; then
    for segment in "${_segments[@]}"; do
      info="$(gaudi::render_segment "$segment")"
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

# Display seconds in human readable fromat
# Based on http://stackoverflow.com/a/32164707/3859566
# USAGE:
#   gaudi::displaytime <seconds>
gaudi::displaytime () {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  [[ $D -gt 0 ]] && printf '%dd ' $D
  [[ $H -gt 0 ]] && printf '%dh ' $H
  [[ $M -gt 0 ]] && printf '%dm ' $M
  printf '%ds' $S
}
