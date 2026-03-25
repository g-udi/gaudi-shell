# shellcheck shell=bash

cite about-completion
about-completion 'Export bash completions'

complete -o nospace -S = -W '$(printenv | awk -F= "{print \$1}")' export
