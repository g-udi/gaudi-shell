# shellcheck shell=bash

cite about-plugin priority
about-plugin 'Load Atuin! The magical shell history via ble.sh'

if [[ ${BLE_VERSION-} ]]; then
	eval "$(atuin init bash)"
fi