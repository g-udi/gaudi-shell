#!/usr/bin/env bash

_finalize_hook_test() {
	export GAUDI_FINALIZE_HOOK_RAN="true"
}

GAUDI_SHELL_FINALIZE_HOOKS+=("_finalize_hook_test")
alias test_finalize_hook="registered"
