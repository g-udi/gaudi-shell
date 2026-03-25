# shellcheck shell=bash
# about-plugin 'Miscellaneous base tools'

# Get all IPs
ips() {
	if _command_exists ifconfig; then
		ifconfig | awk '/inet /{ gsub(/addr:/, ""); print $2 }'
	elif _command_exists ip; then
		ip addr | awk '/inet /{ print $2 }'
	fi
}

# Get external IP
myip() {
	curl -s https://api.ipify.org && echo
}

# Make a directory and cd into it
mkcd() {
	mkdir -p "$1" && cd "$1" || return
}

# Generate a random password
passgen() {
	local length=${1:-16}
	LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom | head -c "$length"
	echo
}

# Pick a random line from a file
pickfrom() {
	local file="${1:-}"
	[[ -z "$file" ]] && echo "usage: pickfrom <file>" && return 1
	shuf -n 1 "$file"
}
