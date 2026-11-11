# shellcheck shell=bash

cite about-plugin
about-plugin 'Initialize jump (see https://github.com/gsamokovarov/jump). Set JUMP_OPTS to change keybinding'

__init_jump () {
  command -v jump &> /dev/null || return 0
  eval "$(jump shell bash "${JUMP_OPTS[@]}")"
}

__init_jump
