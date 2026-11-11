# shellcheck shell=bash

cite about-plugin
about-plugin 'OSX specific functions'

# Everything here is macOS only
[[ "$OSTYPE" == darwin* ]] || return 0

# OS X: Open new tabs in same directory
if [[ "$OSTYPE" == darwin* ]]; then
  if type update_terminal_cwd > /dev/null 2>&1 ; then
    if ! [[ $PROMPT_COMMAND =~ (^|;)update_terminal_cwd($|;) ]] ; then
      PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND%;};}update_terminal_cwd"
      declared="$(declare -p PROMPT_COMMAND 2>/dev/null || :)"
      if [[ "$declared" =~ \ -[aAilrtu]*x[aAilrtu]*\  ]]; then
        export PROMPT_COMMAND
      fi
    fi
  fi
fi

tab () {
  about 'Opens a new terminal tab'
  group 'OSX'

  osascript 2>/dev/null <<EOF
    tell application "System Events"
      tell process "Terminal" to keystroke "t" using command down
    end
    tell application "Terminal"
      activate
      do script with command " cd \"$PWD\"; $*" in window 0
    end tell
EOF
}

# renames the current os x terminal tab title
tabname () {
  about 'Renames the current terminal tab'
  param '1: title'
  group 'OSX'

  printf '\e]1;%s\a' "$1"
}

# renames the current os x terminal window title
winname () {
  about 'Renames the current terminal window'
  param '1: title'
  group 'OSX'

  printf '\e]2;%s\a' "$1"
}

pman () {
    about 'View man documentation in Preview'
    example '$ pman bash'
    group 'OSX'
    local preview_app="${PREVIEW:-Preview}"
    man -t "${1}" | open -fa "$preview_app"
}

pri () {
    about 'display information about Ruby classes, modules, or methods, in Preview'
    param '1: Ruby method, module, or class'
    example '$ pri Array'
    group 'OSX'
    local preview_app="${PREVIEW:-Preview}"
    ri -T "${1}" | open -fa "$preview_app"
}

# Download a file and open it in Preview
prevcurl () {
  about 'Download a file and open it in Preview'
  group 'OSX'

  if [[ ! $(uname) = "Darwin" ]]
  then
    echo "This only works with Mac OS X"
    return 1
  fi
  local preview_app="${PREVIEW:-Preview}"
  curl "$@" | open -fa "$preview_app"
}

refresh-launchpad () {
  about 'Reset launchpad layout in macOS'
  example '$ refresh-launchpad'
  group 'OSX'

  if [[ $(uname) = "Darwin" ]];then
    defaults write com.apple.dock ResetLaunchPad -bool TRUE
    killall Dock
  else
    echo "Sorry, this only works on Mac OS X"
  fi
}

# Fills JVMS_DIR and JVMS, which the caller declares local
_osx-jvms-scan () {
  JVMS_DIR="/Library/Java/JavaVirtualMachines"
  JVMS=()

  if [[ ! -d "$JVMS_DIR" ]]; then
    echo "No JVM directory found at $JVMS_DIR" >&2
    return 1
  fi

  # No mapfile: this file also loads in bash 3.2
  local _jvm
  while IFS= read -r _jvm; do
    JVMS+=("$_jvm")
  done < <(find "$JVMS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
}

list-jvms () {
  about 'List java virtual machines and their states in macOS'
  example 'list-jvms'
  group 'OSX'

  local JVMS_DIR i
  local -a JVMS JVMS_STATES
  _osx-jvms-scan || return 1

  # Map state of JVM
  for (( i = 0; i < ${#JVMS[@]}; i++ )); do
    if [[ -f "${JVMS_DIR}/${JVMS[$i]}/Contents/Info.plist" ]]; then
      JVMS_STATES[i]=enabled
    else
      JVMS_STATES[i]=disabled
    fi
      echo "${i} ${JVMS[$i]} ${JVMS_STATES[$i]}"
  done
}

pick-default-jvm () {
  about 'Pick the default Java Virtual Machines in system-wide scope in macOS'
  example 'pick-default-jvm'
  group 'OSX'

  # Declare variables
  local JVMS_DIR i
  local -a JVMS
  local DEFAULT_JVM_DIR=""
  local DEFAULT_JVM=""
  local OPTION=""

  # Call for listing
  list-jvms
  _osx-jvms-scan || return 1

  # OPTION for default jdk and set variables
  while [[ ! "$OPTION" =~ ^[0-9]+$ || OPTION -ge "${#JVMS[@]}" ]]; do
    read -r -p "Enter Default JVM: " OPTION
      if [[ ! "$OPTION" =~ ^[0-9]+$  ]]; then
        echo "Please enter a number"
      fi

      if [[ OPTION -ge "${#JVMS[@]}" ]]; then
        echo "Please select one of the displayed JVMs"
      fi
  done

  DEFAULT_JVM_DIR="${JVMS_DIR}/${JVMS[$OPTION]}"
  DEFAULT_JVM="${JVMS[$OPTION]}"

  # The renames below need sudo: say what will happen and ask first
  echo "This renames Contents/Info.plist of every JVM in ${JVMS_DIR} except ${DEFAULT_JVM} to Info.plist.disable, using sudo."
  _read_input "Continue? [y/n]"
  [[ "$REPLY" == [yY] ]] || return 1

  # Disable all jdk
  for (( i = 0; i < ${#JVMS[@]}; i++ )); do
    if [[ -f "${JVMS_DIR}/${JVMS[$i]}/Contents/Info.plist" ]]; then
      sudo mv "${JVMS_DIR}/${JVMS[$i]}/Contents/Info.plist" "${JVMS_DIR}/${JVMS[$i]}/Contents/Info.plist.disable"
    fi
  done

  # Enable default jdk
  if [[ -f "${DEFAULT_JVM_DIR}/Contents/Info.plist.disable" ]]; then
    sudo mv "${DEFAULT_JVM_DIR}/Contents/Info.plist.disable" "${DEFAULT_JVM_DIR}/Contents/Info.plist"
    echo "Enabled ${DEFAULT_JVM} as default JVM"
  fi
}

# Make this backwards compatible
alias pcurl='prevcurl'

# From http://apple.stackexchange.com/questions/110343/copy-last-command-in-terminal
copyLastCmd () {
  about 'Copies the last command to the clipboard'
  group 'OSX'

  fc -ln -1 | awk '{$1=$1}1' | pbcopy
}
