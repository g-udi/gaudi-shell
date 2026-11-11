#!/usr/bin/env bats
# shellcheck shell=bats
# shellcheck disable=SC2030,SC2031

# Smoke tests for the zsh adapter: every test runs a small script in `zsh -f`
# (no user configuration) against the test copy of gaudi-shell.

load "$GAUDI_TEST_DIRECTORY"/helper.bash

local_setup() {
	command -v zsh >/dev/null 2>&1 || skip "zsh is not installed"

	export TERM="xterm-256color"
	ZSH_SCRIPT="$BATS_TEST_TMPDIR/smoke.zsh"
	ZSH_OUT="$BATS_TEST_TMPDIR/zsh.out"
	ZSH_ERR="$BATS_TEST_TMPDIR/zsh.err"

	# The theme prints glyphs, which zsh refuses to do outside a UTF-8 locale
	local utf8_locale
	utf8_locale="$(locale -a 2>/dev/null | grep -i -m 1 -E '^(en_US|C)\.utf-?8$')"
	[[ -n "$utf8_locale" ]] && export LC_ALL="$utf8_locale"
	return 0
}

# Writes a script that sources the adapter and then runs the body from stdin.
_write_zsh_script() {
	{
		# shellcheck disable=SC2016
		printf '%s\n' 'source "$GAUDI_SHELL/adapters/zsh/init.zsh"'
		cat
	} >"$ZSH_SCRIPT"
}

# Runs the script, keeping standard output and standard error apart.
_run_zsh_script() {
	zsh -f "$ZSH_SCRIPT" >"$ZSH_OUT" 2>"$ZSH_ERR"
}

@test "zsh adapter: loads and runs the core commands without errors" {
	_write_zsh_script <<'SCRIPT'
print -r -- "shell=$GAUDI_SHELL_CURRENT"
gshell help
gshell enable alias general
gshell enable alias git
gshell show
gshell show aliases enabled
gshell disable alias git
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	assert_output ""

	run cat "$ZSH_OUT"
	assert_line "shell=zsh"
	assert_line --partial "Usage: gshell <command> [args]"
	assert_line --partial "enabled with priority"
	assert_line --regexp "^general +.*◉"
	assert_line --partial "◯ disabled"
}

@test "zsh adapter: enabled components are loaded" {
	ln -s "../aliases/general.aliases.bash" "$GAUDI_SHELL/components/enabled/150___general.aliases.bash"
	cat >"$GAUDI_SHELL/components/aliases/zsh-smoke.aliases.bash" <<'ALIASES'
alias zsh_smoke_alias='echo smoke'
ALIASES
	ln -s "../aliases/zsh-smoke.aliases.bash" "$GAUDI_SHELL/components/enabled/150___zsh-smoke.aliases.bash"

	_write_zsh_script <<'SCRIPT'
alias zsh_smoke_alias
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_OUT"
	assert_line "zsh_smoke_alias='echo smoke'"
}

@test "zsh adapter: pathmunge changes PATH" {
	_write_zsh_script <<'SCRIPT'
PATH="/usr/bin:/bin"
pathmunge "/tmp/fake one:/tmp/fake-two"
print -r -- "prepend=$PATH"
pathmunge "/tmp/fake-two"
pathmunge "/tmp/fake-three" after
print -r -- "after=$PATH"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	assert_output ""
	run cat "$ZSH_OUT"
	assert_line "prepend=/tmp/fake one:/tmp/fake-two:/usr/bin:/bin"
	assert_line "after=/tmp/fake one:/tmp/fake-two:/usr/bin:/bin:/tmp/fake-three"
}

@test "zsh adapter: _read_input reads an answer and stops when there is none" {
	_write_zsh_script <<'SCRIPT'
print y | { _read_input "Sure?" >/dev/null; print -r -- "yes=$? reply=$REPLY"; }
print n | { _read_input "Sure?" >/dev/null; print -r -- "no=$? reply=$REPLY"; }
_read_input "Sure?" >/dev/null </dev/null
print -r -- "eof=$? reply=$REPLY"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	assert_output ""
	run cat "$ZSH_OUT"
	assert_line "yes=0 reply=y"
	assert_line "no=1 reply=n"
	assert_line "eof=2 reply="
}

@test "zsh adapter: backup, profile, help and search print no variable assignments" {
	_write_zsh_script <<'SCRIPT'
gshell enable alias general >/dev/null
gshell enable alias git >/dev/null
gshell enable plugin base >/dev/null
gshell enable plugin git >/dev/null
print -r -- "--- backup"
gshell backup
print -r -- "--- profile"
gshell profile save smoke
gshell profile save other
gshell profile list
gshell profile load smoke
print -r -- "--- help"
gshell help aliases
gshell help plugins
print -r -- "--- search"
gshell search git
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_OUT"
	assert_line "Backing up alias: general"
	assert_line "Backing up plugin: git"
	assert_line --partial "Profile saved:"
	refute_line --regexp '^_?[a-zA-Z_]+=[^ ]*$'

	run cat "$ZSH_ERR"
	refute_output --partial "read-only"
	refute_output --partial "bad option"
}

@test "zsh adapter: the gaudi theme renders a prompt with the default segments" {
	export GAUDI_SHELL_THEME="gaudi"
	_write_zsh_script <<'SCRIPT'
cd "$GAUDI_SHELL"
gaudi::prompt
print -r -- "PROMPT=$PROMPT"
print -r -- "LEFT=$_GAUDI_RENDERED_LEFT"
for segment in "${GAUDI_PROMPT_LEFT[@]}" "${GAUDI_PROMPT_RIGHT[@]}" "${GAUDI_PROMPT_ASYNC[@]}"; do
	(( ${+functions[gaudi_$segment]} )) || print -r -- "not loaded: $segment"
done
print -r -- "precmd=${precmd_functions[*]}"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_OUT"
	assert_output --partial "%F{2}>>%f "
	assert_line --partial "gaudi-shell"
	assert_line --partial "precmd=_gaudi_zsh_precmd"
	refute_output --partial "not loaded"

	run cat "$ZSH_ERR"
	refute_output --partial "command not found"
	refute_output --partial "bad substitution"
}

@test "zsh adapter: prompt text is never expanded again, with or without PROMPT_SUBST" {
	export GAUDI_SHELL_THEME="gaudi"
	export GAUDI_CWD_SHORTEN="false"

	local work="$BATS_TEST_TMPDIR/work"
	mkdir -p "$work"
	cd "$work"
	git init -q .
	git commit -q --allow-empty -m init
	# shellcheck disable=SC2016
	git checkout -q -b '$(touch${IFS}pwned-branch)'
	# shellcheck disable=SC2016
	mkdir -p '$(touch pwned-dir)/`touch pwned-tick`/100%F{red}%n'
	# shellcheck disable=SC2016
	cd '$(touch pwned-dir)/`touch pwned-tick`/100%F{red}%n'

	_write_zsh_script <<'SCRIPT'
GAUDI_PROMPT_LEFT=(cwd)
GAUDI_PROMPT_RIGHT=(user)
GAUDI_PROMPT_ASYNC=(scm)

unsetopt PROMPT_SUBST
gaudi::prompt
expanded="$(print -P -- "$PROMPT $RPROMPT")"
print -r -- "plain: ${expanded//$'\n'/ }"

setopt PROMPT_SUBST
gaudi::prompt
print -r -- "subst-prompt: ${PROMPT//$'\n'/ }"
expanded="$(print -P -- "$PROMPT $RPROMPT")"
print -r -- "subst: ${expanded//$'\n'/ }"
SCRIPT

	_run_zsh_script </dev/null

	run find "$work" -name 'pwned*' -type f
	assert_output ""

	run cat "$ZSH_OUT"
	# With PROMPT_SUBST the prompt only references the rendered text
	# shellcheck disable=SC2016
	assert_line --partial 'subst-prompt:  ${_GAUDI_RENDERED_LEFT}'
	# Hostile names and % sequences are displayed literally in both modes
	# shellcheck disable=SC2016
	assert_line --regexp '^plain: .*\$\(touch pwned-dir\)/`touch pwned-tick`/100%F\{red\}%n'
	# shellcheck disable=SC2016
	assert_line --regexp '^subst: .*\$\(touch pwned-dir\)/`touch pwned-tick`/100%F\{red\}%n'
}

@test "zsh adapter: theme segment files are sourced once, not on every prompt" {
	export GAUDI_SHELL_THEME="gaudi"
	export GAUDI_PROBE_LOG="$BATS_TEST_TMPDIR/probe.log"
	cat >"$GAUDI_SHELL/components/themes/bash/gaudi/segments/probe.bash" <<'SEGMENT'
echo "sourced" >>"$GAUDI_PROBE_LOG"
gaudi_probe() {
	printf 'probe-output'
}
SEGMENT

	_write_zsh_script <<'SCRIPT'
GAUDI_PROMPT_LEFT=(probe)
GAUDI_PROMPT_RIGHT=()
GAUDI_PROMPT_ASYNC=()
gaudi::prompt
gaudi::prompt
gaudi::prompt
print -r -- "LEFT=$_GAUDI_RENDERED_LEFT"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_OUT"
	assert_line "LEFT=probe-output"
	run cat "$GAUDI_PROBE_LOG"
	assert_output "sourced"
}

@test "zsh adapter: gshell update works and leaves the current directory alone" {
	(
		cd "$GAUDI_SHELL" || exit 1
		git init -q .
		git add -A
		GIT_AUTHOR_DATE="2020-01-01T12:00:00Z" GIT_COMMITTER_DATE="2020-01-01T12:00:00Z" git commit -q -m "one"
		git tag v0.0.1
		git clone -q --bare . "$BATS_TEST_TMPDIR/remote.git"
		git remote add origin "$BATS_TEST_TMPDIR/remote.git"
		git clone -q "$BATS_TEST_TMPDIR/remote.git" "$BATS_TEST_TMPDIR/other"
		cd "$BATS_TEST_TMPDIR/other" || exit 1
		GIT_AUTHOR_DATE="2021-01-01T12:00:00Z" GIT_COMMITTER_DATE="2021-01-01T12:00:00Z" git commit -q --allow-empty -m "two"
		git tag v0.0.2
		git push -q origin HEAD --tags
	) >/dev/null 2>&1
	mkdir -p "$BATS_TEST_TMPDIR/elsewhere"
	cd "$BATS_TEST_TMPDIR/elsewhere"

	_write_zsh_script <<'SCRIPT'
# Never re-exec the shell under test
_gaudi-shell-restart() { print -r -- "RESTART"; }
print n | gshell update
print -r -- "declined: pwd=${PWD:t} stack=${#dirstack}"
print y | gshell update
print -r -- "accepted: pwd=${PWD:t} stack=${#dirstack}"
SCRIPT

	_run_zsh_script </dev/null

	run cat "$ZSH_ERR"
	refute_output --partial "read-only variable"
	run cat "$ZSH_OUT"
	assert_line --partial "Not updating"
	assert_line "declined: pwd=elsewhere stack=0"
	assert_line --partial "gaudi-shell successfully updated."
	assert_line "RESTART"
	assert_line "accepted: pwd=elsewhere stack=0"
	assert_equal "$(git -C "$GAUDI_SHELL" describe --tags)" "v0.0.2"
}
