# shellcheck shell=bash

cite about-alias
about-alias 'Curl aliases for convenience.'

_set_curl_aliases () {
	if command -v curl > /dev/null 2>&1; then
		# follow redirects
    alias cl='curl -L'
    # follow redirects, download as original name
    alias clo='curl -L -O'
    # follow redirects, download as original name, continue
    alias cloc='curl -L -C - -O'
    # follow redirects, download as original name, continue, retry 5 times
    alias clocr='curl -L -C - -O --retry 5'
    # follow redirects, fetch banner
    alias clb='curl -L -I'
		# see only response headers from a get request
		alias clhead='curl -D - -so /dev/null'
	fi
}

_set_curl_aliases
unset -f _set_curl_aliases
