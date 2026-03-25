# gaudi-shell

A cross-shell framework for managing aliases, plugins, completions, and themes across **bash**, **zsh**, and **fish**.

## Design

gaudi-shell is built on three principles:

1. **Write once, run everywhere** — Aliases are defined as declarative YAML files that work in all shells. Plugins that only use POSIX features are written once in `.sh` and sourced by bash and zsh automatically.

2. **Shell-specific when needed** — When a feature requires shell-specific syntax (key bindings, completions, prompt themes), each shell gets its own implementation in `bash/`, `zsh/`, or `fish/` subdirectories.

3. **POSIX core, thin adapters** — The component registry, loader, profiles, and CLI are written in POSIX sh. Each shell has a thin adapter (`adapters/<shell>/init.*`) that sources the core and sets up shell-specific hooks.

## Architecture

```
gaudi-shell/
  core/
    registry.sh          # Enable/disable/list/search components (POSIX sh)
    loader.sh            # Load enabled components in priority order
    profiles.sh          # Save/load/list/rm named configurations
    cli.sh               # CLI dispatcher (gaudi <command>)
  adapters/
    bash/init.bash       # Bash init — source from ~/.bash_profile
    zsh/init.zsh         # Zsh init — source from ~/.zshrc
    fish/init.fish       # Fish init — source from ~/.config/fish/config.fish
  components/
    aliases/             # Declarative YAML aliases (cross-shell)
      git.yaml
      general.yaml
    plugins/
      posix/             # POSIX sh plugins (bash + zsh compatible)
      bash/              # Bash-specific plugins
      zsh/               # Zsh-specific plugins
      fish/              # Fish-specific plugins
    completions/
      bash/              # Bash completions
      zsh/               # Zsh completions
      fish/              # Fish completions
    themes/
      bash/              # Bash prompt themes
      zsh/               # Zsh prompt themes
      fish/              # Fish prompt themes
  registry/
    enabled/             # Symlinks to enabled components (runtime state)
  profiles/              # Saved named configurations
```

## How Components Work

### Aliases (cross-shell)

Aliases are YAML files with a flat `key: value` structure:

```yaml
name: git
description: Common git abbreviations

aliases:
  ga: git add
  gc: git commit
  gs: git status
```

When enabled, gaudi-shell parses the YAML and generates the correct alias syntax for the current shell. One file, three shells.

### Plugins (POSIX or shell-specific)

Plugins in `plugins/posix/` are written in POSIX sh and work in both bash and zsh:

```sh
# components/plugins/posix/extract.sh
extract() {
    case "$1" in
        *.tar.gz)  tar xzf "$1" ;;
        *.zip)     unzip "$1" ;;
        # ...
    esac
}
```

For features requiring shell-specific APIs (key bindings, line editing), write separate implementations in `plugins/bash/`, `plugins/zsh/`, and `plugins/fish/`.

### Completions and Themes

These are inherently shell-specific. Each shell has its own directory.

## Installation

```bash
git clone https://github.com/g-udi/gaudi-shell.git ~/.gaudi-shell
```

### Bash

Add to `~/.bash_profile` or `~/.bashrc`:

```bash
export GAUDI_SHELL="$HOME/.gaudi-shell"
source "$GAUDI_SHELL/adapters/bash/init.bash"
```

### Zsh

Add to `~/.zshrc`:

```zsh
export GAUDI_SHELL="$HOME/.gaudi-shell"
source "$GAUDI_SHELL/adapters/zsh/init.zsh"
```

### Fish

Add to `~/.config/fish/config.fish`:

```fish
set -gx GAUDI_SHELL "$HOME/.gaudi-shell"
source "$GAUDI_SHELL/adapters/fish/init.fish"
```

## Usage

```sh
gaudi show                     # list all enabled components
gaudi show aliases             # list all available aliases
gaudi enable alias git         # enable the git aliases
gaudi disable plugin sudo      # disable the sudo plugin
gaudi search docker            # search for docker-related components
gaudi profile save work        # save current setup as "work"
gaudi profile load minimal     # switch to "minimal" profile
gaudi profile list             # list saved profiles
gaudi reload                   # restart shell with fresh session
gaudi version                  # show version info
```

`g` is a shortcut for `gaudi`.

## Component Resolution Order

When enabling a component, gaudi-shell looks for the source file in this order:

1. **Declarative YAML** — `components/aliases/<name>.yaml`
2. **Shell-specific** — `components/<type>/<current-shell>/<name>.<shell>`
3. **POSIX fallback** — `components/<type>/posix/<name>.sh`

This means a plugin written in POSIX sh is automatically available in bash and zsh without duplication.

## Priority System

Components load in priority order via numeric prefixes on symlinks:

| Type | Default Priority |
|------|-----------------|
| Aliases | 150 |
| Plugins | 250 |
| Completions | 350 |

Lower numbers load first. This ensures aliases are available before plugins run.
