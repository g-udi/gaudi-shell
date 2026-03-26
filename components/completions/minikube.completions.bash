
# shellcheck shell=bash

cite about-completion
about-completion 'Minikube (Local Kubernetes) completion'

if command -v minikube &>/dev/null
then
  eval "$(minikube completion bash)"
fi
