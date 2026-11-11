# shellcheck shell=bash

cite about-plugin
about-plugin 'Toggle sudo with ESC-ESC'

# Toggle sudo at the beginning of the current or the previous command by
# hitting the ESC key twice
if [[ -n "${BASH_VERSION:-}" ]]; then
	sudo-command-line() {
		about "toggle sudo at the beginning of the current or the previous command by hitting the ESC key twice"
		group "sudo"

		[[ ${#READLINE_LINE} -eq 0 ]] && READLINE_LINE=$(fc -l -n -1 | xargs)
		if [[ $READLINE_LINE == sudo\ * ]]; then
			READLINE_LINE="${READLINE_LINE#sudo }"
		else
			READLINE_LINE="sudo $READLINE_LINE"
		fi
		READLINE_POINT=${#READLINE_LINE}
	}

	# Define shortcut keys: [Esc] [Esc]
	# bind -x needs an interactive shell and the readline of bash 4 or later
	if [[ $- == *i* ]] && [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
		bind -x '"\e\e": sudo-command-line'
	fi
elif [[ -n "${ZSH_VERSION:-}" ]]; then
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
