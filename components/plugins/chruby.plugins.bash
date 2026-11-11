# shellcheck shell=bash
# shellcheck disable=SC1091

cite about-plugin
about-plugin 'Load chruby (from the Homebrew prefix, /usr/local or /usr)'

for _gaudi_chruby_prefix in "${GAUDI_HOST_HOMEBREW_PREFIX:-}" "${HOMEBREW_PREFIX:-}" /opt/homebrew /usr/local /usr; do
  if [[ -n "$_gaudi_chruby_prefix" && -f "${_gaudi_chruby_prefix}/share/chruby/chruby.sh" ]]; then
    # shellcheck source=/dev/null
    source "${_gaudi_chruby_prefix}/share/chruby/chruby.sh"
    if [[ -f "${_gaudi_chruby_prefix}/share/chruby/auto.sh" ]]; then
      # shellcheck source=/dev/null
      source "${_gaudi_chruby_prefix}/share/chruby/auto.sh"
    fi
    break
  fi
done
unset _gaudi_chruby_prefix
