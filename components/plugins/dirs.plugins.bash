# shellcheck shell=bash
# shellcheck disable=SC1090

cite about-plugin
about-plugin 'Directory stack navigation'

alias d="dirs -v -l"
# Change to location in stack by number
alias 1="pushd"
alias 2="pushd +2"
alias 3="pushd +3"
alias 4="pushd +4"
alias 5="pushd +5"
alias 6="pushd +6"
alias 7="pushd +7"
alias 8="pushd +8"
alias 9="pushd +9"

# Clone this location
alias pc="pushd \$(pwd)"

# Push new location
alias pu="pushd"

# Pop current location
alias po="popd"

dirs-help () {
  about 'Directory navigation alias usage'
  group 'Dirs'

  echo "Directory Navigation Alias Usage"
  echo
  echo "Use the power of directory stacking to move"
  echo "between several locations with ease."
  echo
  echo "d	: Show directory stack."
  echo "po	: Remove current location from stack."
  echo "pc	: Adds current location to stack."
  echo "pu <dir>: Adds given location to stack."
  echo "1	: Change to stack location 1."
  echo "2	: Change to stack location 2."
  echo "3	: Change to stack location 3."
  echo "4	: Change to stack location 4."
  echo "5	: Change to stack location 5."
  echo "6	: Change to stack location 6."
  echo "7	: Change to stack location 7."
  echo "8	: Change to stack location 8."
  echo "9	: Change to stack location 9."
}

# Add bookmarking functionality
if [[ ! -f ~/.dirs ]]; then  # if doesn't exist, create it
    touch ~/.dirs
else
    source ~/.dirs
fi

alias L='cat ~/.dirs'

# Goes to destination dir, otherwise stay in the dir
G () {
    about 'Goes to destination dir'
    example '$ G ..'
    group 'Dirs'

    cd "${1:-$(pwd)}" || return ;
}

# Save a bookmark
S () {
    about 'save a bookmark'
    example '$ S mybkmrk'
    group 'Dirs'

    [[ $# -eq 1 ]] || { echo "${FUNCNAME[0]} function requires 1 argument"; return 1; }

    sed "/$*/d" ~/.dirs > ~/.dirs1;
    \mv ~/.dirs1 ~/.dirs;
    echo "$*"=\""$(pwd)"\" >> ~/.dirs;
    source ~/.dirs ;
}

# Remove a bookmark
R () {
    about 'Remove a bookmark'
    example '$ R mybkmrk'
    group 'Dirs'

    [[ $# -eq 1 ]] || { echo "${FUNCNAME[0]} function requires 1 argument"; return 1; }

    sed "/$*/d" ~/.dirs > ~/.dirs1;
    \mv ~/.dirs1 ~/.dirs;
}

# Update bookmark stack
alias U='source ~/.dirs'

# Set the Bash option so that no '$' is required when using the above facility
shopt -s cdable_vars
