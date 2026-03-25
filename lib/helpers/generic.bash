#!/usr/bin/env bash
# shellcheck shell=bash

# Add a directory to PATH if not already present
pathmunge() {
	[[ -z "$1" ]] && return
	if [[ -d "$1" ]]; then
		if ! echo "$PATH" | tr ':' '\n' | grep -qx "$1"; then
			if [[ "$2" == "after" ]]; then
				PATH="$PATH:$1"
			else
				PATH="$1:$PATH"
			fi
		fi
	fi
}
