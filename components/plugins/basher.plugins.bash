# shellcheck shell=bash

cite about-plugin
about-plugin 'Initializes basher, the shell package manager'

if [[ -x "$HOME/.basher/bin/basher" ]]; then
	pathmunge "$HOME/.basher/bin"
	eval "$(basher init - bash)"
else
	_log_warning 'basher not found'
	return 0
fi	
