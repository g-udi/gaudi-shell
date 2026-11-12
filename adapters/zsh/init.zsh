#!/usr/bin/env zsh
#
# gaudi-shell zsh adapter
#
# Add to your ~/.zshrc:
#   export GAUDI_SHELL="$HOME/.gaudi-shell"
#   source "$GAUDI_SHELL/adapters/zsh/init.zsh"

: "${GAUDI_SHELL:=${0:A:h}/../..}"

# Initialize the zsh completion system (needed for compdef), unless it already
# is: a second compinit would only repeat the work of the first. The directory
# of the dump file is created first; without it compinit cannot write the dump
# and rebuilds everything on every start.
if (( ! ${+functions[compdef]} )); then
  _gaudi_shell_zcompdump_dir="${XDG_CACHE_HOME:-$HOME/.cache}/gaudi-shell"
  [[ -d "$_gaudi_shell_zcompdump_dir" ]] || mkdir -p "$_gaudi_shell_zcompdump_dir" 2>/dev/null
  autoload -Uz compinit && compinit -i -d "$_gaudi_shell_zcompdump_dir/zcompdump" 2>/dev/null
  unset _gaudi_shell_zcompdump_dir
fi

# Provide bash builtins that zsh lacks, unless something already did: a
# `complete` from bashcompinit, loaded before this file, is kept.
(( ${+functions[shopt]} )) || shopt() { true; }
(( ${+functions[complete]} )) || complete() { true; }

# Safe zsh options for bash compatibility. They are set for the whole session
# (the shared components rely on them); see "Zsh options" in the README.
# DO NOT set KSH_ARRAYS — it breaks macOS Terminal, zsh internals, and PATH handling.
setopt NO_NOMATCH       # Don't error on failed globs
setopt BASH_REMATCH     # Populate BASH_REMATCH for =~ regex

source "$GAUDI_SHELL/gaudi_shell.sh"
