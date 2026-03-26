# gaudi-shell

A cross-shell framework for managing aliases, plugins, completions, and themes across **bash** and **zsh**.

Evolved from [gaudi-bash](https://github.com/g-udi/gaudi-bash), gaudi-shell keeps the same proven architecture — symlink-based component management, priority-sorted loading, profiles — while adding native zsh support. Most components work in both shells without modification.

## Installation

```bash
git clone https://github.com/g-udi/gaudi-shell.git ~/.gaudi-shell
cd ~/.gaudi-shell && ./setup.sh
```

The setup script backs up your existing shell config, writes the gaudi-shell template, and enables a sane set of defaults (general aliases, base plugin, system completions).

Options:

- `--silent` (`-s`): Install with defaults without prompting
- `--no-modify-config` (`-n`): Do not modify your existing config file

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

## Quick Start

```bash
gaudi show                        # see what's currently enabled
gaudi show plugins                # browse all available plugins
gaudi enable plugin fzf           # enable a plugin
gaudi enable alias git            # enable git aliases
gaudi enable completion docker    # enable docker tab completion
gaudi disable plugin nvm          # disable a plugin
gaudi search docker               # find docker-related components
gaudi reload                      # reload your shell to apply changes
```

`g` is a shortcut for `gaudi` — use `g show`, `g enable alias git`, etc.

Tab completion works in both bash and zsh for all commands and component names.

## Architecture

```
gaudi-shell/
  gaudi_shell.sh           # Entry point (sourced by adapters)
  lib/
    gaudi-shell.bash       # CLI dispatcher (gaudi show, enable, disable, ...)
    composure.bash         # Compatibility stubs for ported components
    log.bash               # Logging subsystem (ERROR, WARNING, DEBUG levels)
    colors.bash            # Terminal color definitions
    command_duration.bash   # Command execution timing
    history.bash           # History configuration
    search.bash            # Component search engine
    appearance.bash        # Theme loading
    helpers/
      cache.bash           # XDG-based component caching
      components.bash      # Component listing and metadata
      core.bash            # Core utilities and describe
      enabler.bash         # Enable components (symlink creation with priority)
      disabler.bash        # Disable components (symlink removal)
      doctor.bash          # Diagnostics (gaudi doctor)
      generic.bash         # pathmunge and utility helpers
      help.bash            # Help display for components
      profile.bash         # Profile save/load/list/rm
      updater.bash         # Git-based update (stable/dev/all modes)
      utils.bash           # General utilities (_command_exists, _is_function, etc.)
  adapters/
    bash/init.bash         # Bash adapter — sources gaudi_shell.sh directly
    zsh/init.zsh           # Zsh adapter — sets up compatibility, then sources gaudi_shell.sh
  components/
    aliases/               # Alias definitions (work in both bash and zsh)
    plugins/               # Plugin definitions (work in both bash and zsh)
    completions/           # Bash completions (.completions.bash) + zsh completion (.zsh)
    themes/                # Prompt themes (bash/ and zsh/ subdirectories)
    enabled/               # Symlinks to enabled components (runtime state)
  scripts/
    loader.bash            # Loads all enabled components in priority-sorted order
  profiles/                # Saved named configurations
```

The core engine loads libraries from `lib/`, then the loader walks `components/enabled/` and sources every enabled alias, plugin, and completion. Components are enabled and disabled by creating or removing symlinks in the `enabled/` directory, managed through the `gaudi enable` and `gaudi disable` commands.

### Design Principles

- **Cross-shell**: aliases and plugins are bash scripts that work in both bash and zsh. Only completions and themes need shell-specific implementations.
- **Symlink-based**: enabling a component creates a symlink; disabling removes it. No config files to edit.
- **Priority-sorted**: components load in numeric order (aliases at 150, plugins at 250, completions at 350) so aliases are available when plugins run.
- **Zero dependencies**: pure bash/zsh — no external tools required to run.

## Commands

```bash
gaudi show                           # list all currently enabled components
gaudi show aliases                   # list all available aliases (enabled and disabled)
gaudi show plugins                   # list all available plugins
gaudi show completions               # list all available completions
gaudi show aliases enabled           # list only enabled aliases

gaudi enable alias git               # enable the git aliases
gaudi enable plugin fzf nvm sudo     # enable multiple plugins at once
gaudi enable completion docker       # enable docker completion
gaudi enable alias all               # enable all aliases

gaudi disable plugin nvm             # disable the nvm plugin
gaudi disable alias all              # disable all aliases

gaudi help aliases                   # show help for enabled aliases
gaudi help plugins                   # show functions defined by enabled plugins

gaudi search ruby                    # find components matching "ruby"
gaudi search git -chruby             # search for git, exclude chruby
gaudi search docker --enable         # search and enable all matches

gaudi profile save work              # save current enabled components as "work" profile
gaudi profile load minimal           # disable everything, then enable from "minimal" profile
gaudi profile list                   # list saved profiles
gaudi profile rm old-setup           # delete a saved profile

gaudi backup                         # back up enabled components to a file
gaudi restore                        # re-enable components from backup

gaudi doctor                         # diagnostic reload with logging (shows all levels)
gaudi doctor errors                  # show only error-level logs
gaudi doctor warnings                # show error + warning logs

gaudi update                         # update gaudi-shell to latest stable tag
gaudi update dev                     # update to latest development branch
gaudi update all                     # update core + sync component submodules

gaudi version                        # show version, git SHA, and shell type
gaudi reload                         # re-source your shell profile
gaudi restart                        # re-exec the shell (stronger than reload)
```

## Components

gaudi-shell ships with 71 plugins, 39 alias sets, and 62 completions.

### Plugins

Plugins add new shell functions, behaviors, and integrations:

- **sudo** -- press Escape twice to toggle `sudo` at the beginning of the current command (native bash + zsh)
- **fzf** -- fuzzy finder integration
- **nvm** -- Node version manager (lazy-loaded for fast startup)
- **pyenv** -- Python version management (lazy-loaded for fast startup)
- **extract** -- extract any archive format with a single command
- **cmd-returned-notify** -- desktop notification when a long-running command finishes
- **python** -- `shttp` for HTTP server, `pyedit` to open Python modules
- **url** -- URL slugify with HTML/MD/RST output formats
- **fasd** / **zoxide** / **autojump** / **jump** -- fast directory navigation
- **git** / **gitstatus** / **git-subrepo** -- Git helpers and status
- **docker** / **docker-compose** -- Docker workflow helpers
- **ssh** / **sshagent** -- SSH agent management
- **tmux** / **tmuxinator** -- Tmux session management
- **direnv** -- per-directory environment variables
- **base** -- utility functions (mkcd, ips, myip, passgen, pickfrom)
- **man** -- colorize man pages
- **history** -- history manipulation
- **encode** / **compress** / **json** -- encoding, compression, JSON tools

### Aliases

Shortcut aliases for frequently used commands:

- **git** -- `ga`, `gc`, `gp`, `gs`, `gl`, `gco`, `gcb`, and more
- **docker** / **docker-compose** -- container shortcuts
- **terraform** -- `tf`, `tfa`, `tfp` (supports both terraform and tofu)
- **kubectl** -- Kubernetes shortcuts
- **directory** -- `..`, `...`, `md`, `rd` navigation
- **general** -- `_` (sudo), `cls`, `h`, `path`
- **composer** -- PHP Composer aliases
- **homebrew** -- Homebrew shortcuts
- **npm** / **yarn** / **node** -- JavaScript tooling
- **tmux** -- terminal multiplexer aliases
- **ls** / **gls** -- listing with colors
- **vim** / **emacs** -- editor shortcuts
- **vagrant** / **vault** -- DevOps tools

### Completions

Tab-completion for 62 tools including:

- **git** / **git_flow** / **github-cli** / **hub** -- Git ecosystem
- **docker** / **docker-compose** / **docker-machine** -- Docker
- **kubectl** / **helm** / **kind** / **minikube** -- Kubernetes
- **terraform** / **vault** / **consul** -- HashiCorp tools
- **cargo** / **rustup** -- Rust toolchain
- **npm** / **nvm** / **yarn** -- JavaScript
- **pip** / **conda** -- Python
- **brew** -- Homebrew
- **ssh** / **gcloud** / **awscli** -- Cloud and system tools
- **gaudi-shell** -- completion for the `gaudi` command itself

## Profiles

Profiles let you save, switch between, and share complete component configurations:

```bash
gaudi profile save mysetup          # save current enabled components
gaudi profile load mysetup          # disable all, re-enable from profile
gaudi profile list                  # list saved profiles with component counts
gaudi profile rm mysetup            # delete a profile
```

Profiles are plain text files in `$GAUDI_SHELL/profiles/` with one component per line:

```
alias general
alias git
plugin base
plugin fzf
completion git
completion docker
```

The `load` command validates the profile before applying changes.

## Command Duration

Track and display how long each command takes:

```bash
export GAUDI_SHELL_COMMAND_DURATION=true
```

| Variable | Default | Description |
|---|---|---|
| `COMMAND_DURATION_MIN_SECONDS` | `1` | Minimum seconds before elapsed time is shown |
| `COMMAND_DURATION_PRECISION` | `1` | Decimal digits for sub-second display |

## Search

Find components by keyword across all types:

```bash
$ gaudi search ruby
      aliases:  bundler rails
      plugins:  chruby ruby
  completions:  bundler gem rake

$ gaudi search docker -machine
      aliases:  docker docker-compose
      plugins:  docker docker-compose
  completions:  docker docker-compose

$ gaudi search git --enable    # search and enable all matches
```

Prefix a term with `-` to exclude it. Use `@` for exact match. Add `--enable` or `--disable` to act on results.

## Priority System

Components load in numeric order via symlink prefixes:

| Type | Default Priority |
|------|-----------------|
| Aliases | 150 |
| Plugins | 250 |
| Completions | 350 |

Lower numbers load first. This ensures aliases are available when plugins run, and plugins are loaded before completions. Override per-component with a comment in the file:

```bash
# GAUDI_SHELL_LOAD_PRIORITY: 375
```

## Backup and Restore

Quick one-off backups:

```bash
gaudi backup     # writes to $GAUDI_SHELL/tmp/enabled.gaudi-shell.backup
gaudi restore    # re-enables from the backup file (validates entries)
```

For named, reusable configurations, use profiles instead.

## Contributing

Components follow a consistent pattern:

```bash
# shellcheck shell=bash
# about-plugin 'Description of what this plugin does'

# Your code here
```

- Aliases use `# about-alias 'description'`
- Plugins use `# about-plugin 'description'`
- Completions use `# about-completion 'description'`

All files should have `# shellcheck shell=bash` as the first line.
