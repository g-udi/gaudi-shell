#!/usr/bin/env bats
# shellcheck shell=bats
# shellcheck disable=SC2034,SC2207

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	load_gaudi_libs gaudi-shell
	source "$GAUDI_SHELL/components/host/gaudi-shell.completions.bash"
}

# Helper: simulate bash tab completion
_complete_at() {
	COMP_WORDS=("$@")
	COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
	COMPREPLY=()
	_gaudi-shell-comp
	echo "${COMPREPLY[*]}"
}

# --- Top-level ---

@test "bash completion: top level lists all commands" {
	run _complete_at gshell ""
	assert_success
	assert_output --partial "show"
	assert_output --partial "enable"
	assert_output --partial "disable"
	assert_output --partial "profile"
	assert_output --partial "version"
}

@test "bash completion: partial match filters results" {
	run _complete_at gshell "en"
	assert_success
	assert_output --partial "enable"
	refute_output --partial "disable"
}

# --- show ---

@test "bash completion: show lists component types" {
	run _complete_at gshell show ""
	assert_success
	assert_output --partial "aliases"
	assert_output --partial "plugins"
	assert_output --partial "completions"
}

# --- enable ---

@test "bash completion: enable lists component types" {
	run _complete_at gshell enable ""
	assert_success
	assert_output --partial "alias"
	assert_output --partial "plugin"
	assert_output --partial "completion"
}

@test "bash completion: enable alias lists available aliases" {
	run _complete_at gshell enable alias ""
	assert_success
	assert_output --partial "git"
	assert_output --partial "all"
}

@test "bash completion: enable plugin lists available plugins" {
	run _complete_at gshell enable plugin ""
	assert_success
	assert_output --partial "sudo"
	assert_output --partial "extract"
	assert_output --partial "all"
}

@test "bash completion: enable alias excludes already enabled" {
	ln -s "$GAUDI_SHELL/components/aliases/lib/git.aliases.bash" \
		"$GAUDI_SHELL/components/enabled/150___git.aliases.bash"

	run _complete_at gshell enable alias "g"
	assert_success
	# git should not appear, but general, gaudi-shell, gls, gitsvn should
	refute_output --partial "git "
}

@test "bash completion: enable offers the framework's own files and never another framework's" {
	run _complete_at gshell enable alias "gaudi"
	assert_success
	assert_output "gaudi-shell"

	run _complete_at gshell enable completion "gaudi"
	assert_output "gaudi-shell"

	run _gaudi-shell-comp-list-available-not-enabled aliases
	refute_output --partial "gaudi-bash"
	run _gaudi-shell-comp-list-available-not-enabled completions
	refute_output --partial "gaudi-bash"
}

# --- disable ---

@test "bash completion: disable plugin lists only enabled plugins" {
	ln -s "$GAUDI_SHELL/components/plugins/lib/base.plugins.bash" \
		"$GAUDI_SHELL/components/enabled/250___base.plugins.bash"

	run _complete_at gshell disable plugin ""
	assert_success
	assert_output --partial "base"
	assert_output --partial "all"
}

@test "bash completion: disable alias with nothing enabled shows only all" {
	run _complete_at gshell disable alias ""
	assert_success
	assert_output "all"
}

# --- profile ---

@test "bash completion: profile lists subcommands" {
	run _complete_at gshell profile ""
	assert_success
	assert_output --partial "save"
	assert_output --partial "load"
	assert_output --partial "list"
	assert_output --partial "rm"
}

# --- doctor ---

@test "bash completion: doctor lists log levels" {
	run _complete_at gshell doctor ""
	assert_success
	assert_output --partial "errors"
	assert_output --partial "warnings"
	assert_output --partial "all"
}

# --- update ---

@test "bash completion: update lists modes" {
	run _complete_at gshell update ""
	assert_success
	assert_output --partial "stable"
	assert_output --partial "dev"
	refute_output --partial "all"
}

# --- no-arg commands ---

@test "bash completion: reload has no further completions" {
	run _complete_at gshell reload ""
	assert_success
	assert_output ""
}

@test "bash completion: version has no further completions" {
	run _complete_at gshell version ""
	assert_success
	assert_output ""
}

# --- driven by the command table ---

@test "bash completion: the top level offers exactly the commands of the command table" {
	run _complete_at gshell ""
	assert_success
	assert_equal "$(tr ' ' '\n' <<<"$output" | sort | tr '\n' ' ')" "$(_gaudi-shell-verb-names | tr ' ' '\n' | sort | tr '\n' ' ')"
}

@test "bash completion: show <type> offers enabled" {
	run _complete_at gshell show aliases ""
	assert_success
	assert_output "enabled"

	run _complete_at gshell show plugins "en"
	assert_output "enabled"

	run _complete_at gshell show plugins enabled ""
	assert_output ""
}

@test "bash completion: search offers its flags" {
	run _complete_at gshell search "--"
	assert_success
	assert_output --partial "--enable"
	assert_output --partial "--disable"
	assert_output --partial "--plugin"
	assert_output --partial "--no-color"
	assert_output --partial "--refresh"

	run _complete_at gshell search git "--e"
	assert_output "--enable"

	run _complete_at gshell search git "--d"
	assert_output "--disable"
}

@test "bash completion: every search flag offered is one the search command handles" {
	local flag
	for flag in $(_gaudi-shell-verb-field search 4); do
		case "$flag" in
		--enable | --disable) continue ;;
		esac
		run grep -c -- "'${flag}')" "$GAUDI_SHELL/lib/search.bash"
		assert_output "1"
	done
}

@test "bash completion: profile load, rm and save offer the saved profiles" {
	mkdir -p "$GAUDI_SHELL/profiles"
	echo "alias general" >"$GAUDI_SHELL/profiles/work.gaudi-shell"

	run _complete_at gshell profile load ""
	assert_success
	assert_output --partial "work"

	run _complete_at gshell profile rm "wo"
	assert_output "work"

	run _complete_at gshell profile list ""
	assert_output ""
}

@test "bash completion: enable and disable complete more than one name" {
	run _complete_at gshell enable alias git "gene"
	assert_success
	assert_output "general"

	ln -s "../plugins/lib/base.plugins.bash" "$GAUDI_SHELL/components/enabled/250___base.plugins.bash"
	run _complete_at gshell disable plugins git "ba"
	assert_output "base"
}
