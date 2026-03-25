# shellcheck shell=bash

cite about-completion
about-completion 'Consul bash completions'

CONSUL_BIN=$(command -v consul 2>/dev/null)

if [[ -x "$CONSUL_BIN" ]]
then
  complete -C "$CONSUL_BIN" consul
fi

unset CONSUL_BIN
