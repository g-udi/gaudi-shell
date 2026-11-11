
# shellcheck shell=bash

cite about-completion
about-completion 'Bash completion support for Capistrano'

_capcomplete () {
    if [[ -f Capfile ]]; then
        local cur
        if declare -F _get_comp_words_by_ref > /dev/null; then
            _get_comp_words_by_ref -n : cur
        else
            cur="${COMP_WORDS[COMP_CWORD]}"
        fi
        # The task list is cached per project under the XDG cache, not in the project
        local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/gaudi-shell/capistrano" recent
        local cache="${cache_dir}/${PWD//\//%}"
        recent=$(ls -t "$cache" Capfile **/*.cap 2> /dev/null | head -n 1)
        if [[ $recent != "$cache" ]]; then
            mkdir -p "$cache_dir" || return 0
            if cap --version | grep -q 'Capistrano v2.'; then
              # Capistrano 2.x
              cap --tool --verbose --tasks | cut -d " " -f 2 > "$cache"
            else
              # Capistrano 3.x
              cap --all --tasks | cut -d " " -f 2 > "$cache"
            fi
        fi
        COMPREPLY=($(compgen -W "$(cat "$cache" 2> /dev/null)" -- "$cur"))
        # Trim the "prefix:" bash already holds, instead of removing ":" from the global COMP_WORDBREAKS
        declare -F __ltrim_colon_completions > /dev/null && __ltrim_colon_completions "$cur"
        return 0
    fi
}

complete -o default -o nospace -F _capcomplete cap
