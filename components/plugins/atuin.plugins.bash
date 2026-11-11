# shellcheck shell=bash

cite about-plugin priority
about-plugin 'Load Atuin! The magical shell history via ble.sh'
# After the blesh plugin (default priority 250), which sets BLE_VERSION
priority "260"

_binary_exists atuin || return 0

if [[ ${BLE_VERSION-} ]]; then
	eval "$(atuin init bash)"
fi
