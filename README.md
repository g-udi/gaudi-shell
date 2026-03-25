# gaudi-shell

A cross-shell framework for managing aliases, plugins, completions, and themes across **bash** and **zsh**.

Evolved from [gaudi-bash](https://github.com/g-udi/gaudi-bash), gaudi-shell keeps the same proven architecture — symlink-based component management, priority-sorted loading, profiles — while adding native zsh support. Most components work in both shells without modification.

## Installation

```bash
git clone https://github.com/g-udi/gaudi-shell.git ~/.gaudi-shell
cd ~/.gaudi-shell && ./setup.sh
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

## Architecture

```
gaudi-shell/
  gaudi_shell.sh         # Entry point (sourced by adapters)
  lib/
    gaudi-shell.bash     # CLI dispatcher
    log.bash             # Logging subsystem
    colors.bash          # Terminal colors
    command_duration.bash # Command timing
    history.bash         # History config
    appearance.bash      # Theme loading
    helpers/
      cache.bash         # XDG-based component caching
      components.bash    # Component listing and metadata
      core.bash          # Core utilities
      enabler.bash       # Enable components (symlink creation)
      disabler.bash      # Disable components (symlink removal)
      doctor.bash        # Diagnostics
      generic.bash       # Path and utility helpers
      help.bash          # Help display
      profile.bash       # Profile save/load/list/rm
      utils.bash         # General utilities
  adapters/
    bash/init.bash       # Bash init (sources gaudi_shell.sh)
    zsh/init.zsh         # Zsh init (sources gaudi_shell.sh with bash compat)
  components/
    aliases/             # Alias definitions (work in both shells)
    plugins/             # Plugin definitions (work in both shells)
    completions/
      bash/              # Bash-specific completions
      zsh/               # Zsh-specific completions
    themes/
      bash/              # Bash prompt themes
      zsh/               # Zsh prompt themes
    enabled/             # Symlinks to enabled components (runtime)
  scripts/
    loader.bash          # Loads enabled components in priority order
```

Components are enabled/disabled by creating or removing symlinks in `components/enabled/`. Most aliases and plugins are plain bash scripts that work in both bash and zsh. Completions and themes are shell-specific.

## Usage

```bash
gaudi show                     # list all enabled components
gaudi show aliases             # list all available aliases
gaudi enable alias git         # enable git aliases
gaudi disable plugin sudo      # disable sudo plugin
gaudi search docker            # search for docker components
gaudi profile save work        # save current config as "work"
gaudi profile load minimal     # switch to "minimal" profile
gaudi profile list             # list saved profiles
gaudi reload                   # reload shell profile
gaudi restart                  # re-exec the shell
gaudi version                  # show version info
gaudi doctor                   # diagnostic reload with logging
```

`g` is a shortcut for `gaudi`.

## Components

### Aliases
Alias files work in both bash and zsh:
- **general** — navigation, common shortcuts
- **git** — git abbreviations

### Plugins
Plugins use bash syntax compatible with both shells:
- **base** — utility functions (mkcd, ips, myip, passgen)
- **extract** — universal archive extractor
- **sudo** — ESC-ESC to toggle sudo (bash and zsh native implementations)

### Completions
Shell-specific, stored in `completions/bash/` and `completions/zsh/`.

### Themes
Shell-specific, stored in `themes/bash/` and `themes/zsh/`.

## Priority System

| Type | Default Priority |
|------|-----------------|
| Aliases | 150 |
| Plugins | 250 |
| Completions | 350 |

Lower numbers load first.
