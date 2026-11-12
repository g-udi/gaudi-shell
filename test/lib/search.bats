#!/usr/bin/env bats
# shellcheck shell=bats
# shellcheck disable=SC2034

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs composure gaudi-shell search
}

@test "gaudi-shell search: exact matches ignore show usage footer tokens" {
	run _gaudi-shell-search @to --no-color

	assert_failure
	assert_output ""
}

@test "gaudi-shell search: help names the gshell command and only the flags that exist" {
	run _gaudi-shell-search --help

	assert_success
	assert_output --partial "gshell search [-|@]term1"
	refute_output --partial "gaudi-shell search"
	refute_output --partial "| -e"
	refute_output --partial "| -d"
	assert_output --partial "--no-color   | -x"
	assert_output --partial "--completion | -c"
}

@test "gaudi-shell search: every short flag in the help is handled by the parser" {
	local flags flag
	flags="$(_gaudi-shell-search --help | sed -n 's/^ *--[a-z-]* *| \(-[a-z]\) .*/\1/p' | sort -u)"
	[[ -n "$flags" ]]
	for flag in $flags; do
		run grep -c -- "'${flag}' | '--" "$GAUDI_SHELL/lib/search.bash"
		assert_output "1"
	done
}

@test "gaudi-shell search: results are printed with real escape sequences, never a literal backslash-e" {
	load_gaudi_libs colors
	# Colours as on a colour terminal, whatever the test runs on
	GREEN=$'\e[0;32m' CYAN=$'\e[0;36m' YELLOW=$'\e[0;33m' NC=$'\e[0m'
	ln -s "../aliases/lib/git.aliases.bash" "$GAUDI_SHELL/components/enabled/150___git.aliases.bash"

	run _gaudi-shell-search git --alias
	assert_success
	assert_output --partial "aliases:"
	assert_output --partial "git ✓"
	assert_output --partial $'\e[0;36m'
	refute_output --partial '\e['
}

@test "gaudi-shell search: the colour variables hold the escape character itself" {
	run grep -c "='\\\\e\\[" "$GAUDI_SHELL/lib/colors.bash"
	assert_output "0"
	run grep -c "=\\\$'\\\\e\\[" "$GAUDI_SHELL/lib/colors.bash"
	assert_output "18"
}

@test "gaudi-shell search: --no-color prints plain text and marks enabled components" {
	ln -s "../aliases/lib/git.aliases.bash" "$GAUDI_SHELL/components/enabled/150___git.aliases.bash"

	run _gaudi-shell-search @git --alias --no-color
	assert_success
	assert_output $'aliases:\tgit ✓\t'
}

@test "gaudi-shell search: --enable and --disable act on the matches" {
	run _gaudi-shell-search @git --alias --enable --no-color
	assert_success
	assert_file_exist "$GAUDI_SHELL/components/enabled/150___git.aliases.bash"
	assert_output --partial "git ✓"

	run _gaudi-shell-search @git --alias --disable --no-color
	assert_success
	assert_file_not_exist "$GAUDI_SHELL/components/enabled/150___git.aliases.bash"
	refute_output --partial "✓"
}

@test "gaudi-shell search: a negative term removes matches" {
	run _gaudi-shell-search git -svn --alias --no-color
	assert_success
	assert_output --partial "git"
	refute_output --partial "gitsvn"
}

@test "gaudi-shell search: succeeds when any type has a match and fails when none has" {
	# There is a "general" alias set, and no completion of that name
	run _gaudi-shell-search @general --no-color
	assert_success
	assert_output --partial "aliases:"
	refute_output --partial "completions:"

	run _gaudi-shell-search no-such-component-anywhere --no-color
	assert_failure
	assert_output ""
}

@test "gaudi-shell search: the colour codes of the component table are not searched" {
	load_gaudi_libs colors
	GREEN=$'\e[0;32m' RED=$'\e[0;31m' NC=$'\e[0m'

	run _gaudi-shell-search '0;31m' --alias --no-color
	assert_failure
	assert_output ""
}

@test "gaudi-shell search: grep is called as a program, never through a variable that could hold an alias" {
	run grep -rn 'GAUDI_SHELL_GREP' "$GAUDI_SHELL/lib" "$GAUDI_SHELL/gaudi_shell.sh"
	assert_failure

	# An alias named egrep, as in a stock Ubuntu ~/.bashrc, changes nothing
	ln -s "../aliases/lib/git.aliases.bash" "$GAUDI_SHELL/components/enabled/150___git.aliases.bash"
	shopt -s expand_aliases
	alias egrep='egrep --color=auto'
	alias grep='grep --color=always'
	run _gaudi-shell-search @git --alias --no-color
	assert_success
	assert_output $'aliases:\tgit ✓\t'
}
