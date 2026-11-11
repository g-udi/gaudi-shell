#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	REPO="$BATS_TEST_TMPDIR/repo"
	OTHER="$BATS_TEST_TMPDIR/installed"
	FAKEBIN="$BATS_TEST_TMPDIR/fakebin"

	# The repository being pushed, with a test runner that says who it is
	mkdir -p "$REPO/test" "$REPO/sub/dir" "$OTHER/test" "$FAKEBIN"
	git init -q "$REPO"
	printf '%s\n' '#!/usr/bin/env bash' 'echo "tests of the pushed repository"' 'cat' >"$REPO/test/run"
	# An installed copy elsewhere, which must not be the one that is tested
	printf '%s\n' '#!/usr/bin/env bash' 'echo "tests of the installed copy"' 'exit 1' >"$OTHER/test/run"
	chmod +x "$REPO/test/run" "$OTHER/test/run"

	# No real pre-commit run from a test
	printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$FAKEBIN/pre-commit"
	chmod +x "$FAKEBIN/pre-commit"
}

@test "gaudi-shell hooks: pre-push tests the repository being pushed, not the installed copy" {
	cd "$REPO/sub/dir"

	run env PATH="$FAKEBIN:$PATH" GAUDI_SHELL="$OTHER" "$GAUDI_SHELL/hooks/pre-push" <<<"refs/heads/main 0000 refs/heads/main 0000"
	assert_success
	assert_output --partial "tests of the pushed repository"
	refute_output --partial "installed copy"
	# The list of refs git feeds the hook does not reach the tests
	refute_output --partial "refs/heads/main"
}

@test "gaudi-shell hooks: pre-push stops the push when the tests fail" {
	printf '%s\n' '#!/usr/bin/env bash' 'exit 1' >"$REPO/test/run"
	cd "$REPO"

	run env PATH="$FAKEBIN:$PATH" "$GAUDI_SHELL/hooks/pre-push" </dev/null
	assert_failure
	assert_output --partial "Tests failed. Push aborted."
}

@test "gaudi-shell hooks: pre-push refuses to run outside a git work tree" {
	mkdir -p "$BATS_TEST_TMPDIR/plain"
	cd "$BATS_TEST_TMPDIR/plain"

	run env PATH="$FAKEBIN:$PATH" GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR" "$GAUDI_SHELL/hooks/pre-push" </dev/null
	assert_failure
	assert_output --partial "not inside a git work tree"
}
