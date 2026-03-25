#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs log gaudi-shell components cache core utils
}

@test "gaudi-shell helpers: components: __check-function-parameters: valid component" {
	run __check-function-parameters plugin
	assert_success
}

@test "gaudi-shell helpers: components: __check-function-parameters: invalid component" {
	run __check-function-parameters invalid
	assert_failure
}

@test "gaudi-shell helpers: components: pluralize" {
	run _gaudi-shell-pluralize-component plugin
	assert_output "plugins"

	run _gaudi-shell-pluralize-component alias
	assert_output "aliases"

	run _gaudi-shell-pluralize-component completion
	assert_output "completions"
}

@test "gaudi-shell helpers: components: singularize" {
	run _gaudi-shell-singularize-component plugins
	assert_output "plugin"

	run _gaudi-shell-singularize-component aliases
	assert_output "alias"

	run _gaudi-shell-singularize-component completions
	assert_output "completion"
}
