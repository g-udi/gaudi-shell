# shellcheck shell=bash

cite about-completion
about-completion 'Kubectl (Kubernetes CLI) completion'

if command -v kubectl &>/dev/null
then
  eval "$(kubectl completion bash)"
fi
