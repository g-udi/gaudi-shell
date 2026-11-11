# shellcheck shell=bash

cite about-plugin
about-plugin 'Syntax-highlight JSON strings or files'

json () {
	about 'Syntax-highlight a JSON string (argument) or stream (stdin)'
	example "\$ json '{\"a\": 1}'"
	group 'json'

	if [[ -t 0 ]]; then
		python3 -m json.tool <<< "$*" | pygmentize -l json;
	else # pipe
		python3 -m json.tool | pygmentize -l json;
	fi;
}
