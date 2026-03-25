# shellcheck shell=bash

cite about-plugin
about-plugin 'SSH helper functions'

add_ssh () {
  about 'Add entry to ssh config (host|hostname|user)'
  group 'ssh'

  [[ $# -ne 3 ]] && echo "add_ssh host hostname user" && return 1
  [[ ! -d ~/.ssh ]] && mkdir -m 700 ~/.ssh
  [[ ! -e ~/.ssh/config ]] && touch ~/.ssh/config && chmod 600 ~/.ssh/config
  echo -en "\n\nHost $1\n  HostName $2\n  User $3\n  ServerAliveInterval 30\n  ServerAliveCountMax 120" >> ~/.ssh/config
}

sshlist () {
  about 'List hosts defined in ssh config'
  group 'ssh'

  awk '$1 ~ /Host$/ {for (i=2; i<=NF; i++) print $i}' ~/.ssh/config
}

ssh-add-all () {
  about 'Add all ssh private keys to agent'
  group 'ssh'

  grep -slR "PRIVATE" ~/.ssh | xargs ssh-add
}
