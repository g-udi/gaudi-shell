# shellcheck shell=bash
# shellcheck disable=SC1090

cite about-plugin
about-plugin 'Sources tmuxinator script if available'

if [[ -s "$HOME/.tmuxinator/scripts/tmuxinator" ]]; then
  # Old tmuxinator releases installed this script
  # shellcheck source=/dev/null
  . "$HOME/.tmuxinator/scripts/tmuxinator"
else
  # Current releases ship a completion script, which Homebrew installs under its prefix
  for _gaudi_tmuxinator_prefix in "${GAUDI_HOST_HOMEBREW_PREFIX:-}" "${HOMEBREW_PREFIX:-}" /opt/homebrew /usr/local; do
    if [[ -n "$_gaudi_tmuxinator_prefix" && -s "${_gaudi_tmuxinator_prefix}/etc/bash_completion.d/tmuxinator" ]]; then
      # shellcheck source=/dev/null
      . "${_gaudi_tmuxinator_prefix}/etc/bash_completion.d/tmuxinator"
      break
    fi
  done
  unset _gaudi_tmuxinator_prefix
fi
