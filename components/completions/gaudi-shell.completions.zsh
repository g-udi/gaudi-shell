#!/usr/bin/env zsh
# Zsh-native tab completion for gshell / g commands.
#
# The candidates come from the same functions the bash completion uses:
# _gaudi-shell-verb-names (lib/gaudi-shell.bash) and _gaudi-shell-comp-words
# (gaudi-shell.completions.bash).

_gaudi-shell-zsh-comp() {
	emulate -L zsh
	# The shared helpers are written for bash: a pattern without matches must
	# stay as it is instead of raising an error.
	setopt no_nomatch

	local -a candidates
	if (( CURRENT <= 2 )); then
		candidates=(${=$(_gaudi-shell-verb-names)})
	else
		candidates=(${=$(_gaudi-shell-comp-words "${words[2]}" $(( CURRENT - 2 )) "${words[3]:-}")})
	fi

	(( ${#candidates} )) && compadd -- "${candidates[@]}"
}

compdef _gaudi-shell-zsh-comp gshell
compdef _gaudi-shell-zsh-comp g
