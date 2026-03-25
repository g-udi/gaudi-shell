#
# gaudi-shell fish adapter
#
# Add to your ~/.config/fish/config.fish:
#   set -gx GAUDI_SHELL "$HOME/.gaudi-shell"
#   source "$GAUDI_SHELL/adapters/fish/init.fish"

if not set -q GAUDI_SHELL
    set -gx GAUDI_SHELL "$HOME/.gaudi-shell"
end

# Fish can't source POSIX sh, so we call the core as external commands
# and handle aliases/plugins natively.

# Load declarative YAML aliases
function __gaudi_load_aliases
    set -l enabled_dir "$GAUDI_SHELL/registry/enabled"
    test -d "$enabled_dir"; or return

    for component in $enabled_dir/*.aliases
        test -L "$component"; or continue
        set -l target (readlink "$component")

        switch (string match -r '\\.\\w+$' "$target")
            case '.yaml'
                __gaudi_load_yaml_aliases "$target"
            case '.fish'
                source "$target"
        end
    end
end

function __gaudi_load_yaml_aliases
    set -l file $argv[1]
    set -l in_aliases 0

    while read -l line
        # Skip empty, comments, metadata
        string match -q '' "$line"; and continue
        string match -q '#*' "$line"; and continue
        string match -q 'name:*' "$line"; and continue
        string match -q 'description:*' "$line"; and continue

        if string match -q 'aliases:' "$line"
            set in_aliases 1
            continue
        end

        if test $in_aliases -eq 1
            set -l trimmed (string trim "$line")
            set -l key (string split ':' "$trimmed")[1]
            set -l value (string trim (string split ':' "$trimmed")[2])

            if test -n "$key" -a -n "$value"
                alias $key="$value"
            end
        end
    end < "$file"
end

# Load fish-specific plugins and completions
function __gaudi_load_fish_components
    set -l enabled_dir "$GAUDI_SHELL/registry/enabled"
    test -d "$enabled_dir"; or return

    for component in $enabled_dir/*.plugins $enabled_dir/*.completions
        test -L "$component"; or continue
        set -l target (readlink "$component")

        switch (string match -r '\\.\\w+$' "$target")
            case '.fish'
                source "$target"
        end
    end
end

# CLI wrapper — calls POSIX core via sh subprocess
function gaudi
    sh -c '. "$GAUDI_SHELL/core/registry.sh" && . "$GAUDI_SHELL/core/loader.sh" && . "$GAUDI_SHELL/core/profiles.sh" && . "$GAUDI_SHELL/core/cli.sh" && gaudi '"(string escape -- $argv)" 2>&1
end

abbr -a g gaudi

# Initialize
__gaudi_load_aliases
__gaudi_load_fish_components
