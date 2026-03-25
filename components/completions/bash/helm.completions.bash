# shellcheck shell=bash

cite about-completion
about-completion 'Helm (Kubernetes Package Manager) completions'

if command -v helm &>/dev/null
then
  eval "$(helm completion bash)"
fi
