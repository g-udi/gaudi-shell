# shellcheck shell=bash

cite about-plugin
about-plugin 'Syntax-highlight JSON strings or files'

json () {
	if [[ -t 0 ]]; then
		python -mjson.tool <<< "$*" | pygmentize -l javascript;
	else # pipe
		python -mjson.tool | pygmentize -l javascript;
	fi;
}
