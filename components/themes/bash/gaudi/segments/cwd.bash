#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2010

#
# Working directory
#
# Current directory. Return only three last items of path

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

GAUDI_CWD_SHOW="${GAUDI_CWD_SHOW=true}"
GAUDI_CWD_SHORTEN="${GAUDI_CWD_SHORTEN=true}"
GAUDI_CWD_SUMMARY="${GAUDI_CWD_SUMMARY=false}"
GAUDI_CWD_PREFIX="${GAUDI_CWD_PREFIX="$GAUDI_PROMPT_DEFAULT_PREFIX"}"
GAUDI_CWD_SUFFIX="${GAUDI_CWD_SUFFIX="$GAUDI_PROMPT_DEFAULT_SUFFIX"}"
GAUDI_CWD_COLOR="${GAUDI_CWD_COLOR="$BACKGROUND_GAUDI_BLUE"}"
GAUDI_CWD_COLOR_LOCKED="${GAUDI_CWD_COLOR_LOCKED="$GAUDI_WHITE$BACKGROUND_GAUDI_RED"}"
GAUDI_CWD_SEPARATOR="${GAUDI_CWD_SEPARATOR=""}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Print the directory $1 (default: $PWD) with the home directory written as "~".
gaudi::tilde_path () {
  local dir="${1-$PWD}"
  if [[ "$dir" == "$HOME" || "$dir" == "$HOME"/* ]]; then
    dir="~${dir#"$HOME"}"
  fi
  printf '%s\n' "$dir"
}

# Print the directory $1 (default: $PWD) in at most $2 characters (default: 33)
# where possible: the home directory becomes "~" and, while the result is too
# long, the longest directory name in the middle is cut to its first character.
# The last name (the directory itself) is always shown in full.
#   ~/Projects/some-client/website/src  ->  ~/P/s/website/src
gaudi::shorten_path () {
  local dir target="${2-33}" rest piece
  local first=0 last i longest longest_length
  local -a parts
  parts=()

  [[ "${1-$PWD}" == "/" ]] && echo "⚠ ROOT" && return
  dir="$(gaudi::tilde_path "${1-$PWD}")"
  [[ ${#dir} -le $target ]] && echo "$dir" && return

  # Split on "/" by hand: the same in bash and zsh, and empty names (the one
  # before a leading "/") are kept. Not called "path": zsh ties that to $PATH.
  rest="$dir"
  while [[ "$rest" == */* ]]; do
    parts+=("${rest%%/*}")
    rest="${rest#*/}"
  done
  parts+=("$rest")

  # zsh arrays start at 1, bash arrays at 0
  [[ -n "${ZSH_VERSION:-}" ]] && first=1
  last=$((first + ${#parts[@]} - 1))

  while [[ ${#dir} -gt $target ]]; do
    longest=-1
    longest_length=1
    i=$((first + 1))
    while [[ $i -lt $last ]]; do
      piece="${parts[$i]}"
      if [[ ${#piece} -gt $longest_length ]]; then
        longest=$i
        longest_length=${#piece}
      fi
      i=$((i + 1))
    done
    # Nothing left to cut
    [[ $longest -lt 0 ]] && break

    piece="${parts[$longest]}"
    parts[longest]="${piece:0:1}"

    dir=""
    i=$first
    while [[ $i -le $last ]]; do
      [[ $i -gt $first ]] && dir+="/"
      dir+="${parts[$i]}"
      i=$((i + 1))
    done
  done

  echo "$dir"
}

# Shows the current directory.
gaudi_cwd () {
  [[ $GAUDI_CWD_SHOW == false ]] && return

  local color
  [[ -w $PWD ]] && color=$GAUDI_CWD_COLOR || color=$GAUDI_CWD_COLOR_LOCKED

  if [[ $GAUDI_CWD_SHORTEN == true ]]; then
    GAUDI_CWD=$(gaudi::shorten_path "$PWD")
  else
    GAUDI_CWD=$(gaudi::tilde_path "$PWD")
  fi
  # shellcheck disable=SC2012
  [[ $GAUDI_CWD_SUMMARY == true ]] && GAUDI_CWD+=" [$(ls -1 | wc -l | sed 's: ::g') Files, $(ls -lah | grep -m 1 total | sed 's/total //')]"

  gaudi::section \
    "$color" \
    "$GAUDI_CWD_PREFIX" \
    "$GAUDI_CWD_SEPARATOR" \
    "$GAUDI_CWD" \
    "$GAUDI_CWD_SUFFIX"
}
