# shellcheck shell=bash

cite about-alias
about-alias 'Puppet aliases'

alias pupval="puppet parser validate *.pp"
alias puplint="puppet-lint *.pp"
alias pupagt="puppet agent -t"
alias pupagtd="puppet agent -t --debug"
alias pupapp="puppet apply"

