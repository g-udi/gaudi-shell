#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC1091

segment="${1:-}"
generation="${2:-}"

[[ -n "$GAUDI_SHELL" && -n "$segment" && -n "$generation" ]] || exit 1

(
  source "$GAUDI_SHELL/components/themes/gaudi/gaudi.theme.bash" > /dev/null 2>&1 || exit 1
  gaudi::refresh_async_segment "$segment" "$generation"
) &
