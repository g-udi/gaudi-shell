#!/usr/bin/env bash
# shellcheck shell=bash

function load_gaudi_libs() {
	for lib in "$@"; do
		# If loading the main CLI, also load all helpers (mirrors gaudi_shell.sh behavior)
		if [[ "$lib" == "gaudi-shell" ]]; then
			for helper in "${GAUDI_SHELL}"/lib/helpers/*.bash; do
				[[ -f "$helper" ]] && load "$helper"
			done
		fi
		local component
		component=$(find "${GAUDI_SHELL}/lib" -type f -iname "${lib}.bash" 2>/dev/null | head -1)
		[[ -n "$component" ]] && load "$component"
	done
	return 0
}

function setup() {
	export GIT_CONFIG_NOSYSTEM
	export XDG_CACHE_HOME="${BATS_TEST_TMPDIR}"

	# Use a fresh copy of the project for each test
	export GAUDI_SHELL="${BATS_TEST_TMPDIR}/gaudi-shell"

	if [[ ! -d "$GAUDI_SHELL" ]]; then
		mkdir -p "$GAUDI_SHELL"
		# Copy everything except .git and bin (test deps)
		tar -C "${GAUDI_SHELL_ORIGIN}" \
			--exclude='.git' \
			--exclude='bin' \
			-cf - . | tar -C "${GAUDI_SHELL}" -xf -
	fi

	# Clean runtime state (the copy may come from a checkout that is in use)
	rm -rf "$GAUDI_SHELL/tmp" "$GAUDI_SHELL/components/enabled"
	rm -f "$GAUDI_SHELL/profiles/backup.gaudi-shell"
	mkdir -p "$GAUDI_SHELL/components/enabled"

	# Tests start inside the sandbox copy, so a relative path such as
	# ./setup.sh can never reach the repository the suite is run from.
	cd "$GAUDI_SHELL" || return 1

	local_setup
}

function setup_file() {
	set -a

	export GAUDI_TEST_RUNNER="enabled"
	export LEGACY_HOME="$HOME"

	load "${GAUDI_TEST_DEPS_DIR}/bats-support/load.bash"
	load "${GAUDI_TEST_DEPS_DIR}/bats-assert/load.bash"
	load "${GAUDI_TEST_DEPS_DIR}/bats-file/load.bash"

	# shellcheck disable=SC2034
	XDG_DUMMY=""
	unset "${!XDG_@}"

	readonly HOME="${BATS_SUITE_TMPDIR?}"
	mkdir -p "${HOME}"

	git config --global user.name "gaudi-shell bats runner"
	git config --global user.email "test@gaudi.shell"
}

function teardown() {
	rm -rf "${GAUDI_SHELL}/components/enabled" 2>/dev/null
	rm -rf "${GAUDI_SHELL}/tmp" 2>/dev/null
}
