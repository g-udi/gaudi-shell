# shellcheck shell=bash

cite about-plugin
about-plugin 'Load Homebrew shell environment and user-local binaries'

_gaudi_brew_binary=""

if command -v brew > /dev/null 2>&1; then
	_gaudi_brew_binary="$(command -v brew)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
	_gaudi_brew_binary="/opt/homebrew/bin/brew"
elif [[ -x /usr/local/bin/brew ]]; then
	_gaudi_brew_binary="/usr/local/bin/brew"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
	_gaudi_brew_binary="/home/linuxbrew/.linuxbrew/bin/brew"
fi

if [[ -n "$_gaudi_brew_binary" ]]; then
	eval "$("$_gaudi_brew_binary" shellenv)"
	export GAUDI_HOST_HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$("$_gaudi_brew_binary" --prefix 2> /dev/null)}"
else
	for _gaudi_brew_prefix in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
		[[ -d "$_gaudi_brew_prefix" ]] || continue
		export GAUDI_HOST_HOMEBREW_PREFIX="$_gaudi_brew_prefix"
		pathmunge "$_gaudi_brew_prefix/bin"
		pathmunge "$_gaudi_brew_prefix/sbin"
		break
	done
fi

_gaudi_brew_local_bin="${GAUDI_BREW_LOCAL_BIN:-$HOME/.local/bin}"
if [[ ":$PATH:" == *":$_gaudi_brew_local_bin:"* ]]; then
	PATH=":$PATH:"
	PATH="${PATH//:$_gaudi_brew_local_bin:/:}"
	PATH="${PATH#:}"
	PATH="${PATH%:}"
	export PATH
fi
pathmunge "$_gaudi_brew_local_bin"

unset _gaudi_brew_binary _gaudi_brew_local_bin _gaudi_brew_prefix
