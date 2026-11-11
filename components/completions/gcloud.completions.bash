# shellcheck shell=bash
# shellcheck disable=SC2045

cite about-completion
about-completion 'Google Cloud bash completions'

_binary_exists gcloud || return 0

# Don't handle completion if it's already managed
complete -p gcloud &> /dev/null && return 0

# Source the completion that ships with the Google Cloud SDK, when it can be found
_gaudi_gcloud_brew="${GAUDI_HOST_HOMEBREW_PREFIX:-${HOMEBREW_PREFIX:-}}"
for _gaudi_gcloud_root in "${CLOUDSDK_ROOT_DIR:-}" "${GOOGLE_SDK_ROOT:-}" \
  "${_gaudi_gcloud_brew:+${_gaudi_gcloud_brew}/share/google-cloud-sdk}" \
  "${_gaudi_gcloud_brew:+${_gaudi_gcloud_brew}/Caskroom/google-cloud-sdk/latest/google-cloud-sdk}" \
  "${HOME}/google-cloud-sdk" /usr/lib/google-cloud-sdk /usr/share/google-cloud-sdk /snap/google-cloud-sdk/current; do
  if [[ -n "$_gaudi_gcloud_root" && -r "${_gaudi_gcloud_root}/completion.bash.inc" ]]; then
    # shellcheck source=/dev/null
    source "${_gaudi_gcloud_root}/completion.bash.inc"
    break
  fi
done
unset _gaudi_gcloud_brew _gaudi_gcloud_root
