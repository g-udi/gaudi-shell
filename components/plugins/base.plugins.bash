# shellcheck shell=bash

cite about-plugin
about-plugin 'Miscellaneous base tools'

# Get all IPs
ips() {
	about 'Display all ip addresses for this host'
	group 'base'

	if _command_exists ifconfig; then
		ifconfig | awk '/inet /{ gsub(/addr:/, ""); print $2 }'
	elif _command_exists ip; then
		ip addr | awk '/inet /{ print $2 }'
	fi
}

# Get external IP
myip() {
	about 'Displays your ip address, as seen by the Internet'
	group 'base'

	curl -s https://api.ipify.org && echo
}

# Make a directory and cd into it
mkcd() {
	about 'Make a directory and cd into it'
	example '$ mkcd foo'
	example '$ mkcd /tmp/img/photos/large'
	group 'base'

	mkdir -p "$1" && cd "$1" || return
}

# Generate a random password
passgen() {
	about 'Generates a random password (16 characters, or the length given)'
	example '$ passgen 24'
	group 'base'

	local length=${1:-16}
	LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom | head -c "$length"
	echo
}

# Pick a random line from a file
pickfrom() {
	about 'Picks random line from file'
	example '$ pickfrom /usr/share/dict/words'
	group 'base'

	local file="${1:-}"
	[[ -z "$file" ]] && echo "usage: pickfrom <file>" && return 1
	shuf -n 1 "$file"
}

down4me () {
    about 'Checks whether a website is down for you, or everybody'
    example '$ down4me http://www.google.com'
    group 'base'

    curl -Ls "http://downforeveryoneorjustme.com/$1" | sed '/just you/!d;s/<[^>]*>//g'
}

pmdown () {
    about 'Preview markdown file in a browser'
    example '$ pmdown README.md'
    group 'base'

    if command -v markdown &>/dev/null
    then
      local html="${TMPDIR:-/tmp}/pmdown-${1##*/}.html"
      markdown "$1" > "$html" || return 1
      if command -v open &>/dev/null; then
        open "$html"
      elif command -v xdg-open &>/dev/null; then
        xdg-open "$html"
      else
        echo "Preview written to $html"
      fi
    else
      echo "You don't have a markdown command installed!"
    fi
}

lsgrep () {
    about 'Search through directory contents with grep'
    group 'base'

    find . -maxdepth 1 -mindepth 1 -print | sed 's#^\./##' | grep -- "$*"
}

quiet () {
    about 'Runs a command in the background with all of its output discarded'
    example '$ quiet open-some-gui-app'
    group 'base'

    (($#)) || return 1
    "$@" &> /dev/null &
}

usage () {
    about 'Disk usage per directory, in Mac OS X and Linux'
    param '1: directory name'
    group 'base'

    if [[ $(uname) = "Darwin" ]]; then
        if [[ -n "$1" ]]; then
            du -hd 1 "$1"
        else
            du -hd 1
        fi

    elif [[ $(uname) = "Linux" ]]; then
        if [[ -n "$1" ]]; then
            du -h --max-depth=1 "$1"
        else
            du -h --max-depth=1
        fi
    fi
}

mkiso () {
    about 'Creates iso from current dir in the parent dir (unless defined)'
    example 'mkiso ISO-Name dest/path src/path'
    group 'base'

    if type "mkisofs" > /dev/null; then
        local isoname="${1:-${PWD##*/}}"
        local destpath="${2:-../}"
        local srcpath="${3:-${PWD}}"

        if [[ ! -f "${destpath}${isoname}.iso" ]]; then
            echo "writing ${isoname}.iso to ${destpath} from ${srcpath}"
            mkisofs -V "${isoname}" -iso-level 3 -r -o "${destpath}${isoname}.iso" "${srcpath}"
        else
            echo "${destpath}${isoname}.iso already exists"
        fi
    else
        echo "mkisofs cmd does not exist, please install cdrtools"
    fi
}

buf () {
    about 'Backup file with timestamp'
    group 'base'

    local filename filetime

    filename=$1
    filetime=$(date +%Y%m%d_%H%M%S)
    cp -a "${filename}" "${filename}_${filetime}"
}

del () {
    about 'Move files to hidden folder in tmp, that gets cleared on each reboot'
    example 'del ./file.txt'
    group 'base'

    mkdir -p /tmp/.trash && mv "$@" /tmp/.trash;
}
