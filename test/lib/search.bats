#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs composure gaudi-shell search
}

@test "gaudi-shell search: exact matches ignore show usage footer tokens" {
	run _gaudi-shell-search @to --no-color

	assert_failure
	assert_output ""
}
