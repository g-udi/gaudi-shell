# shellcheck shell=bash

cite about-completion
about-completion 'Vue.js completions'

if _command_exists vue; then
    __vuejs_completion()  {
        local opts=(--version --help create add invoke inspect serve build ui init config upgrade info)
        COMPREPLY=()
        for _opt_ in "${opts[@]}"; do
            if [[ "$_opt_" == "$2"* ]]; then
                COMPREPLY+=("$_opt_")
            fi
        done
    }

    complete -F __vuejs_completion vue
fi
