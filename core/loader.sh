#!/usr/bin/env sh
# shellcheck shell=sh
#
# gaudi-shell component loader
#
# POSIX-compatible loader that sources enabled components in priority order.
# Each shell adapter calls this after setting up shell-specific hooks.

gaudi_load_components() {
    local enabled_dir shell
    enabled_dir="$(gaudi_enabled_dir)"
    shell="$(gaudi_detect_shell)"

    [ -d "$enabled_dir" ] || return 0

    for component in "$enabled_dir"/*; do
        [ -e "$component" ] || continue

        local target
        if [ -L "$component" ]; then
            target="$(readlink "$component")"
        else
            target="$component"
        fi

        local ext="${target##*.}"

        case "$ext" in
            yaml)
                # Declarative alias — generate and eval for current shell
                gaudi_load_yaml_aliases "$target" "$shell"
                ;;
            sh)
                # POSIX-compatible — source in any shell
                . "$target"
                ;;
            bash)
                [ "$shell" = "bash" ] && . "$target"
                ;;
            zsh)
                [ "$shell" = "zsh" ] && . "$target"
                ;;
            fish)
                # Fish can't source from here — handled by fish adapter
                ;;
            *)
                # Try to source it regardless
                . "$target" 2>/dev/null
                ;;
        esac
    done
}

# Load aliases from a YAML file
# Simple parser for flat key: value YAML (no nesting, no arrays)
gaudi_load_yaml_aliases() {
    local file="$1" shell="$2"
    local line key value

    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        case "$line" in
            "" | "#"* | "name:"* | "description:"*) continue ;;
            "aliases:") continue ;;
        esac

        # Strip leading whitespace
        line="${line#"${line%%[![:space:]]*}"}"

        # Parse "key: value" pairs
        key="${line%%:*}"
        value="${line#*: }"

        [ -z "$key" ] || [ -z "$value" ] && continue

        case "$shell" in
            bash | zsh)
                alias "${key}=${value}"
                ;;
            fish)
                # Fish aliases are handled by the fish adapter
                ;;
        esac
    done < "$file"
}
