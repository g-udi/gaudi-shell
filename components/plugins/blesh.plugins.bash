# shellcheck shell=bash
# shellcheck disable=1090

cite about-plugin
about-plugin 'Load ble.sh, the Bash line editor!'

if [[ ${BLE_VERSION-} ]]; then
	_log_warning "ble.sh is already loaded!"
	return
fi

_bash_it_ble_path=${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh
if [[ -f $_bash_it_ble_path ]]; then
	source "$_bash_it_ble_path" --attach=prompt
else
	_log_error "Could not find ble.sh in $_bash_it_ble_path, please install using the following command: git clone https://github.com/akinomyoga/ble.sh && make -C ble.sh install"
fi
unset _bash_it_ble_path
