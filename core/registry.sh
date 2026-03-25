#!/usr/bin/env sh
# shellcheck shell=sh
#
# gaudi-shell component registry
#
# POSIX-compatible core that works across bash, zsh, and can be called from fish.
# Manages enabling, disabling, listing, and searching components.
# No bashisms — pure POSIX sh.

GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR="___"
GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_ALIASES=150
GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_PLUGINS=250
GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_COMPLETIONS=350

# Detect current shell
gaudi_detect_shell() {
    if [ -n "$BASH_VERSION" ]; then
        echo "bash"
    elif [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$FISH_VERSION" ]; then
        echo "fish"
    else
        echo "sh"
    fi
}

# Get the gaudi-shell root directory
gaudi_root() {
    echo "${GAUDI_SHELL:-$HOME/.gaudi-shell}"
}

# Get the enabled components directory
gaudi_enabled_dir() {
    echo "$(gaudi_root)/registry/enabled"
}

# Get the component source path
# $1: type (aliases|plugins|completions|themes)
# $2: name
# $3: shell (bash|zsh|fish|posix) — optional, auto-detected
gaudi_component_source() {
    local type="$1" name="$2" shell="${3:-$(gaudi_detect_shell)}"
    local root
    root="$(gaudi_root)"

    # For aliases, check declarative YAML first, then shell-specific
    if [ "$type" = "aliases" ]; then
        if [ -f "$root/components/aliases/${name}.yaml" ]; then
            echo "$root/components/aliases/${name}.yaml"
            return 0
        fi
    fi

    # Check shell-specific first, then posix fallback
    if [ -f "$root/components/${type}/${shell}/${name}.${shell}" ]; then
        echo "$root/components/${type}/${shell}/${name}.${shell}"
        return 0
    fi

    if [ -f "$root/components/${type}/posix/${name}.sh" ]; then
        echo "$root/components/${type}/posix/${name}.sh"
        return 0
    fi

    return 1
}

# Enable a component
# $1: type (alias|plugin|completion|theme)
# $2: name
gaudi_enable() {
    local type="$1" name="$2"
    local plural_type priority source enabled_dir link_name

    plural_type="$(gaudi_pluralize "$type")"
    priority="$(gaudi_default_priority "$plural_type")"
    source="$(gaudi_component_source "$plural_type" "$name")"
    enabled_dir="$(gaudi_enabled_dir)"

    if [ -z "$source" ]; then
        echo "error: ${type} '${name}' not found" >&2
        return 1
    fi

    mkdir -p "$enabled_dir"

    link_name="${priority}${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}${name}.${plural_type}"

    # Check if already enabled
    for existing in "$enabled_dir"/*"${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}${name}.${plural_type}" 2>/dev/null; do
        if [ -e "$existing" ]; then
            echo "${type} '${name}' is already enabled"
            return 0
        fi
    done

    ln -s "$source" "$enabled_dir/$link_name"
    echo "enabled ${type}: ${name} (priority ${priority})"
}

# Disable a component
# $1: type (alias|plugin|completion|theme)
# $2: name
gaudi_disable() {
    local type="$1" name="$2"
    local plural_type enabled_dir

    plural_type="$(gaudi_pluralize "$type")"
    enabled_dir="$(gaudi_enabled_dir)"

    for link in "$enabled_dir"/*"${GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR}${name}.${plural_type}" 2>/dev/null; do
        if [ -e "$link" ] || [ -L "$link" ]; then
            rm "$link"
            echo "disabled ${type}: ${name}"
            return 0
        fi
    done

    echo "error: ${type} '${name}' is not enabled" >&2
    return 1
}

# List components
# $1: type (aliases|plugins|completions|themes)
# $2: mode (all|enabled) — default: all
gaudi_list() {
    local type="$1" mode="${2:-all}"
    local root shell enabled_dir
    root="$(gaudi_root)"
    shell="$(gaudi_detect_shell)"
    enabled_dir="$(gaudi_enabled_dir)"

    if [ "$mode" = "enabled" ]; then
        for link in "$enabled_dir"/*".${type}" 2>/dev/null; do
            [ -e "$link" ] || continue
            local base
            base="$(basename "$link")"
            # Strip priority prefix and type suffix
            base="${base#*"$GAUDI_SHELL_LOAD_PRIORITY_SEPARATOR"}"
            base="${base%.${type}}"
            echo "$base"
        done
    else
        # List all available: check posix + shell-specific + yaml
        for dir in "$root/components/${type}/posix" "$root/components/${type}/${shell}" "$root/components/${type}"; do
            [ -d "$dir" ] || continue
            for file in "$dir"/*; do
                [ -f "$file" ] || continue
                local base
                base="$(basename "$file")"
                base="${base%.*}"
                echo "$base"
            done
        done | sort -u
    fi
}

# Search components by keyword
# $1: search term
gaudi_search() {
    local term="$1"
    local type

    for type in aliases plugins completions; do
        local matches
        matches="$(gaudi_list "$type" | grep -i "$term" 2>/dev/null)"
        if [ -n "$matches" ]; then
            printf "  %s:\t%s\n" "$type" "$(echo "$matches" | tr '\n' ' ')"
        fi
    done
}

# Pluralize component type
gaudi_pluralize() {
    case "$1" in
        alias) echo "aliases" ;;
        *s)    echo "$1" ;;
        *)     echo "${1}s" ;;
    esac
}

# Singularize component type
gaudi_singularize() {
    case "$1" in
        aliases)     echo "alias" ;;
        plugins)     echo "plugin" ;;
        completions) echo "completion" ;;
        themes)      echo "theme" ;;
        *)           echo "$1" ;;
    esac
}

# Get default priority for a component type
gaudi_default_priority() {
    case "$1" in
        aliases)     echo "$GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_ALIASES" ;;
        plugins)     echo "$GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_PLUGINS" ;;
        completions) echo "$GAUDI_SHELL_LOAD_PRIORITY_DEFAULT_COMPLETIONS" ;;
        *)           echo "250" ;;
    esac
}
