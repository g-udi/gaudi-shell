#!/usr/bin/env bats
# shellcheck shell=bats

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	export TERM="xterm-256color"
	export GAUDI_SHELL_THEME="gaudi"
	export GAUDI_CWD_SHORTEN="false"
	PROMPT_SCRIPT="$BATS_TEST_TMPDIR/prompt.bash"
}

# Writes a script that loads gaudi-shell with the gaudi theme, runs the body
# given on stdin and is executed by the bash that is running the suite.
_write_prompt_script() {
	{
		# shellcheck disable=SC2016
		printf '%s\n' 'source "$GAUDI_SHELL/adapters/bash/init.bash"'
		cat
	} >"$PROMPT_SCRIPT"
}

# Creates a git work tree whose branch and directories are named like shell
# command substitutions, and moves into the innermost directory.
_enter_hostile_directory() {
	local work="$BATS_TEST_TMPDIR/work"

	mkdir -p "$work"
	cd "$work" || return 1
	git init -q .
	git commit -q --allow-empty -m init
	# shellcheck disable=SC2016
	git checkout -q -b '$(touch${IFS}pwned-branch)'
	# shellcheck disable=SC2016
	mkdir -p '$(touch pwned-dir)/`touch pwned-tick`'
	# shellcheck disable=SC2016
	cd '$(touch pwned-dir)/`touch pwned-tick`' || return 1
}

@test "gaudi theme: bash prompt: segment text is referenced from PS1, never pasted into it" {
	_enter_hostile_directory

	_write_prompt_script <<'SCRIPT'
GAUDI_PROMPT_LEFT=(cwd)
GAUDI_PROMPT_RIGHT=()
GAUDI_PROMPT_ASYNC=(scm)
gaudi::prompt
printf 'PS1=%s\n' "$PS1"
printf 'LINE=%s\n' "$_GAUDI_RENDERED_LINE"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	# shellcheck disable=SC2016
	assert_line 'PS1=\n${_GAUDI_RENDERED_LINE}\n\n\[${GAUDI_GREEN}\]>>\[${NC}\] '
	# The hostile names are shown as plain text
	# shellcheck disable=SC2016
	assert_output --partial '$(touch pwned-dir)/`touch pwned-tick`'
	# shellcheck disable=SC2016
	assert_output --partial '$(touch${IFS}pwned-branch)'
}

@test "gaudi theme: bash prompt: a directory or branch named like a command substitution is not executed" {
	if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
		skip "needs bash 4.4+ to expand a prompt string with \${PS1@P}"
	fi
	_enter_hostile_directory

	# The eval keeps bash 3.2 from choking on the @P operator while parsing.
	_write_prompt_script <<'SCRIPT'
GAUDI_PROMPT_LEFT=(cwd)
GAUDI_PROMPT_RIGHT=()
GAUDI_PROMPT_ASYNC=(scm)

gaudi::prompt
eval ': "${PS1@P}"'

shopt -u promptvars
gaudi::prompt
eval ': "${PS1@P}"'
case "$PS1" in *'${_GAUDI_RENDERED_LINE}'*) echo "reference left in PS1 with promptvars off" ;; esac

GAUDI_SPLIT_PROMPT=false
shopt -s promptvars
gaudi::prompt
eval ': "${PS1@P}"'
echo "rendered"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_line "rendered"
	refute_output --partial "reference left in PS1"

	run find "$BATS_TEST_TMPDIR/work" -name 'pwned*' -type f
	assert_output ""
}

@test "gaudi theme: bash prompt: backslashes in segment text stay literal when promptvars is off" {
	if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
		skip "needs bash 4.4+ to expand a prompt string with \${PS1@P}"
	fi
	mkdir -p "$BATS_TEST_TMPDIR/back\\wslash"
	cd "$BATS_TEST_TMPDIR/back\\wslash"

	_write_prompt_script <<'SCRIPT'
GAUDI_PROMPT_LEFT=(cwd)
GAUDI_PROMPT_RIGHT=()
GAUDI_PROMPT_ASYNC=()
GAUDI_SPLIT_PROMPT=false
shopt -u promptvars
gaudi::prompt
eval 'printf "%s\n" "${PS1@P}"'
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_output --partial 'back\wslash'
}

@test "gaudi theme: segment files are sourced once, not on every prompt" {
	cat >"$GAUDI_SHELL/components/themes/bash/gaudi/segments/probe.bash" <<'SEGMENT'
echo "sourced" >>"$GAUDI_PROBE_LOG"
gaudi_probe() {
	printf 'probe-output'
}
SEGMENT
	export GAUDI_PROBE_LOG="$BATS_TEST_TMPDIR/probe.log"

	_write_prompt_script <<'SCRIPT'
# Changing the configuration after start-up loads the new segment lazily
GAUDI_PROMPT_LEFT=(probe)
GAUDI_PROMPT_RIGHT=()
GAUDI_PROMPT_ASYNC=()
gaudi::prompt
gaudi::prompt
gaudi::prompt
printf 'LINE=%s\n' "$_GAUDI_RENDERED_LINE"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	assert_output --partial "probe-output"

	run cat "$GAUDI_PROBE_LOG"
	assert_output "sourced"
}

@test "gaudi theme: the default segments are loaded when the theme starts" {
	_write_prompt_script <<'SCRIPT'
for segment in "${GAUDI_PROMPT_LEFT[@]}" "${GAUDI_PROMPT_RIGHT[@]}" "${GAUDI_PROMPT_ASYNC[@]}"; do
	type -t "gaudi_${segment}" >/dev/null || echo "not loaded: ${segment}"
done
echo "checked"
SCRIPT

	run "$BASH" --noprofile --norc "$PROMPT_SCRIPT"
	assert_success
	refute_output --partial "not loaded"
	assert_line "checked"
}
