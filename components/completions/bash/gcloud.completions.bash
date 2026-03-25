# shellcheck shell=bash
# shellcheck disable=SC2045

cite about-completion
about-completion 'Google Cloud bash completions'

_command_exists gcloud || return

# if which gcloud >/dev/null 2>&1; then
#   GOOGLE_SDK_ROOT=${GOOGLE_SDK_ROOT:-$(gcloud info --format="value(installation.sdk_root)")}
#   for i in $(ls ${GOOGLE_SDK_ROOT}/*.bash.inc); do
#     source $i
#   done
# fi
