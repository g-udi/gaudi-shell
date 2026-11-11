# shellcheck shell=bash
# shellcheck disable=SC1090

cite about-plugin priority
about-plugin 'Load fzf, a Command-line fuzzy finder written in Go'
# Load after the system completion to make sure that the fzf completions are working
priority "375"

if [ -r ~/.fzf.bash ] ; then
  # shellcheck source=/dev/null
  source ~/.fzf.bash
elif [ -r "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.bash ] ; then
  # shellcheck source=/dev/null
  source "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.bash
fi

# No need to continue if the command is not present
_command_exists fzf || return 0

if [ -z ${FZF_DEFAULT_COMMAND+x}  ] && _binary_exists fd ; then
  export FZF_DEFAULT_COMMAND='fd --type f'
fi

fe() {
  about "Open the selected file in the default editor"
  group "FZF"
  param "1: Search term"
  example "fe foo"

  local file
  local -a files
  files=()
  # No mapfile: this file also loads in bash 3.2
  while IFS= read -r file; do
    files+=("$file")
  done < <(fzf-tmux --query="$1" --multi --select-1 --exit-0)
  ((${#files[@]})) && "${EDITOR:-vim}" "${files[@]}"
}

fcd() {
  about "cd to the selected directory"
  group "FZF"
  param "1: Directory to browse, or . if omitted"
  example "fcd aliases"

  local dir
  dir=$(find "${1:-.}" -path '*/\.*' -prune \
	                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir" || return
}
