# shellcheck shell=bash

cite about-completion
about-completion 'Bash completion support for Rake, Ruby Make'

_rakecomplete () {
    if [[ -f Rakefile ]]; then
        local cur
        if declare -F _get_comp_words_by_ref > /dev/null; then
            _get_comp_words_by_ref -n : cur
        else
            cur="${COMP_WORDS[COMP_CWORD]}"
        fi
        # The task list is cached per project under the XDG cache, not in the project
        local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/${GAUDI_HOST_NAME:-gaudi}/rake" recent
        local cache="${cache_dir}/${PWD//\//%}"
        recent=$(ls -t "$cache" Rakefile **/*.rake 2> /dev/null | head -n 1)
        if [[ $recent != "$cache" ]]; then
            mkdir -p "$cache_dir" && rake --silent --tasks | cut -d " " -f 2 > "$cache"
        fi
        COMPREPLY=($(compgen -W "$(cat "$cache" 2> /dev/null)" -- "$cur"))
        # Trim the "prefix:" bash already holds, instead of removing ":" from the global COMP_WORDBREAKS
        declare -F __ltrim_colon_completions > /dev/null && __ltrim_colon_completions "$cur"
        return 0
    fi
}

complete -o default -o nospace -F _rakecomplete rake
