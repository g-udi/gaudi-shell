# shellcheck shell=bash

cite about-completion
about-completion 'Openshift bash completions'

_command_exists oc && source <(oc completion bash)
