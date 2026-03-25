#
# sudo — press ESC-ESC to toggle sudo at the beginning of the current command
# Zsh-specific (uses zle widget)

sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}

zle -N sudo-command-line
bindkey "\e\e" sudo-command-line
