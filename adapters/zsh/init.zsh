#!/usr/bin/env zsh
#
# gaudi-shell zsh adapter
#
# Add to your ~/.zshrc:
#   export GAUDI_SHELL="$HOME/.gaudi-shell"
#   source "$GAUDI_SHELL/adapters/zsh/init.zsh"

: "${GAUDI_SHELL:=${0:A:h}/../..}"

# Make zsh compatible with bash syntax used in gaudi-shell core
setopt SH_WORD_SPLIT    # Split unquoted parameter expansions like bash
setopt KSH_ARRAYS       # 0-indexed arrays like bash
setopt NO_NOMATCH       # Don't error on failed globs
setopt BASH_REMATCH     # Populate BASH_REMATCH for =~ regex
setopt KSH_GLOB         # Bash-style glob patterns

# Provide bash builtins that zsh lacks
if ! whence shopt &>/dev/null; then
	shopt() { true; }
fi

# complete -p is bash-only; stub it for zsh
if ! whence -w 'complete' | grep -q builtin; then
	complete() { true; }
fi

# Initialize zsh completion system (needed for compdef)
autoload -Uz compinit && compinit -i -d "${XDG_CACHE_HOME:-$HOME/.cache}/gaudi-shell/zcompdump" 2>/dev/null

source "$GAUDI_SHELL/gaudi_shell.sh"
