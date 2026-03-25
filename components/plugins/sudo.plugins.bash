# shellcheck shell=bash
# about-plugin 'Toggle sudo with ESC-ESC'

if [[ -n "$BASH_VERSION" ]]; then
	sudo-command-line() {
		[[ ${#READLINE_LINE} -eq 0 ]] && READLINE_LINE=$(fc -l -n -1 | xargs)
		if [[ $READLINE_LINE == sudo\ * ]]; then
			READLINE_LINE="${READLINE_LINE#sudo }"
		else
			READLINE_LINE="sudo $READLINE_LINE"
		fi
		READLINE_POINT=${#READLINE_LINE}
	}
	[[ "${BASH_VERSINFO[0]}" -ge 4 ]] && bind -x '"\e\e": sudo-command-line'
elif [[ -n "$ZSH_VERSION" ]]; then
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
fi
