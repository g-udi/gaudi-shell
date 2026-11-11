# shellcheck shell=bash

cite about-completion
about-completion 'Consul bash completions'

if CONSUL_BIN=$(command -v consul); then
  complete -C "$CONSUL_BIN" consul
fi

unset CONSUL_BIN
