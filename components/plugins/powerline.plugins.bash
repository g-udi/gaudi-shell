# shellcheck shell=bash

cite about-plugin
about-plugin 'Enables powerline daemon'

_command_exists powerline-daemon || return
powerline-daemon -q

#the following should not be executed if bashit powerline themes in use
case "${GAUDI_SHELL_THEME:-${BASH_IT_THEME:-}}" in
	*powerline*)
		return
		;;
esac
POWERLINE_BASH_CONTINUATION=1
POWERLINE_BASH_SELECT=1
bashPowerlineInit="$("${PYTHON:-python3}" -c \
	"import os; \
	import powerline;\
	print(os.path.join(os.path.dirname(\
	powerline.__file__),\
	'bindings', \
	'bash', \
	'powerline.sh'))")"
[ -e $bashPowerlineInit ] || return
source $bashPowerlineInit
