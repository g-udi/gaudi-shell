#!/usr/bin/env zsh
#
# gaudi-shell zsh adapter
#
# Add to your ~/.zshrc:
#   export GAUDI_SHELL="$HOME/.gaudi-shell"
#   source "$GAUDI_SHELL/adapters/zsh/init.zsh"

: "${GAUDI_SHELL:=${0:A:h}/../..}"

# Initialize zsh completion system (needed for compdef)
autoload -Uz compinit && compinit -i -d "${XDG_CACHE_HOME:-$HOME/.cache}/gaudi-shell/zcompdump" 2>/dev/null

# Provide bash builtins that zsh lacks
shopt() { true; }
complete() { true; }

# Safe zsh options for bash compatibility.
# DO NOT set KSH_ARRAYS — it breaks macOS Terminal, zsh internals, and PATH handling.
setopt NO_NOMATCH       # Don't error on failed globs
setopt BASH_REMATCH     # Populate BASH_REMATCH for =~ regex

source "$GAUDI_SHELL/gaudi_shell.sh"
