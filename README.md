# gaudi-shell

A cross-shell framework for managing aliases, plugins, completions, and themes across **bash** and **zsh**.

Evolved from [gaudi-bash](https://github.com/g-udi/gaudi-bash), gaudi-shell keeps the same proven architecture — symlink-based component management, priority-sorted loading, profiles — while adding native zsh support. Most components work in both shells without modification.

## Why gaudi-shell?

Years ago I forked [bash-it](https://github.com/Bash-it/bash-it) into [gaudi-bash](https://github.com/g-udi/gaudi-bash) and rewrote large parts of it — cleaner architecture, async theme rendering, better component management, and a curated set of plugins that actually work well together. It became my daily driver for bash.

Then I started using zsh more. And I hit a gap.

The zsh ecosystem has plenty of frameworks and plugin managers — [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh), [prezto](https://github.com/sorin-ionescu/prezto), [antidote](https://github.com/mattmc3/antidote), [zinit](https://github.com/zdharma-continuum/zinit), [zplug](https://github.com/zplug/zplug), [sheldon](https://github.com/rossmacarthur/sheldon), [zgenom](https://github.com/jandamm/zgenom), [antigen](https://github.com/zsh-users/antigen), among others. But they all solve a different problem: they manage *zsh-specific* plugin installation and loading. None of them give you the workflow I was used to — an intuitive `enable plugin fzf` / `disable alias git` CLI, symlink-based component management, profiles to save and switch configurations, or a single `search` command to find what's available across aliases, plugins, and completions. And critically, none of them work across shells.

On the bash side, the options are even more limited. [bash-it](https://github.com/Bash-it/bash-it) (which gaudi-bash forked from) is essentially the only framework with a comparable component management approach.

I found myself context-switching between two completely different mental models depending on which shell I opened. Different config patterns, different commands, different plugin ecosystems.

gaudi-shell closes that gap. **One framework, one CLI, one set of components — across bash and zsh.**

What makes it different:

- **Cross-shell by design**: aliases and plugins are plain bash scripts that work in both shells. Only completions and themes need shell-specific versions. No duplication, no maintaining parallel configs.
- **Intuitive component management**: `gshell enable plugin fzf` works the same in bash and zsh. No editing config files, no sourcing order puzzles, no plugin spec syntax to learn.
- **Batteries included**: ships with 71 plugins, 39 alias sets, and 62 completions — curated and ready to use. No need to find and wire up third-party repositories.
- **Profiles**: save your entire setup as a named profile (`gshell profile save work`), switch between configurations (`gshell profile load minimal`), share them across machines.
- **Search**: `gshell search docker` finds every docker-related alias, plugin, and completion in one shot. Add `--enable` to activate all matches.
- **Proven foundation**: built on years of real-world use in [gaudi-bash](https://github.com/g-udi/gaudi-bash) — segment-based prompt theme, priority-sorted loading, diagnostic tooling (`gshell doctor`).

If you're someone who uses both bash and zsh and wants **one consistent experience** instead of maintaining two separate shell configurations — that's what this is for.

## Installation

```bash
git clone https://github.com/g-udi/gaudi-shell.git ~/.gaudi-shell
cd ~/.gaudi-shell && ./setup.sh
```

The setup script backs up your existing shell config (to a `.bak` file), appends the gaudi-shell template to it or replaces it (it asks which), and enables a sane set of defaults (general aliases, base plugin, system and `gshell` completions).

Options:

- `--help` (`-h`): Display the usage message
- `--silent` (`-s`): Install with defaults without prompting
- `--no-modify-config` (`-n`): Do not modify your existing config file
- `--shell bash|zsh`: Install for a specific shell instead of auto-detecting from `$SHELL`

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
gshell show                       # see what's currently enabled
gshell show plugins               # browse all available plugins
gshell enable plugin fzf          # enable a plugin
gshell enable alias git           # enable git aliases
gshell enable completion docker   # enable docker tab completion
gshell disable plugin nvm         # disable a plugin
gshell search docker              # find docker-related components
gshell reload                     # reload your shell to apply changes
```

`g` is a shortcut for `gshell` — use `g show`, `g enable alias git`, etc.

Tab completion for `gshell` (and `g`) works in both bash and zsh for all commands and component names.

## Architecture

```
gaudi-shell/
  gaudi_shell.sh           # Entry point (sourced by adapters)
  lib/
    gaudi-shell.bash       # CLI dispatcher (gshell show, enable, disable, ...)
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
      doctor.bash          # Diagnostics (gshell doctor)
      generic.bash         # pathmunge and utility helpers
      help.bash            # Help display for components
      profile.bash         # Profile save/load/list/rm
      updater.bash         # Git-based update (stable/dev modes)
      utils.bash           # General utilities (_command_exists, _is_function, etc.)
  adapters/
    bash/init.bash         # Bash adapter — sources gaudi_shell.sh directly
    zsh/init.zsh           # Zsh adapter — sets up compatibility, then sources gaudi_shell.sh
  components/
    aliases/               # Alias definitions (work in both bash and zsh)
    plugins/               # Plugin definitions (work in both bash and zsh)
    completions/           # Bash completions (.completions.bash) + zsh completion for gshell (.zsh)
    themes/                # Prompt themes, per shell (ships bash/gaudi, which also runs in zsh)
    enabled/               # Symlinks to enabled components (runtime state)
    custom/                # Untracked local scripts loaded after enabled components
  scripts/
    loader.bash            # Loads all enabled components in priority-sorted order
  profiles/                # Saved named configurations
```

The core engine loads libraries from `lib/`, then the loader walks `components/enabled/` and sources every enabled alias, plugin, and completion. Components are enabled and disabled by creating or removing symlinks in the `enabled/` directory, managed through the `gshell enable` and `gshell disable` commands.

### Design Principles

- **Cross-shell**: aliases and plugins are bash scripts that work in both bash and zsh. Only completions and themes need shell-specific implementations.
- **Symlink-based**: enabling a component creates a symlink; disabling removes it. No config files to edit.
- **Priority-sorted**: components load in numeric order (aliases at 150, plugins at 250, completions at 350) so aliases are available when plugins run.
- **Zero dependencies**: pure bash/zsh — nothing to install beyond git and the standard Unix tools.

## Local Untracked Customizations

Use `components/custom/` for machine-local aliases, functions, exports, and plugin-like behavior that should not be committed.

```bash
mkdir -p "$GAUDI_SHELL/components/custom"
cat > "$GAUDI_SHELL/components/custom/100-local.aliases.bash" <<'EOF'
# shellcheck shell=bash
alias work='cd ~/Projects'
alias kctx='kubectl config current-context'
EOF
```

Files under `components/custom/` are ignored by git and sourced after enabled components. Prefix filenames with numbers if you need deterministic ordering, for example `100-env.bash`, `200-aliases.bash`, and `900-overrides.bash`.

You can keep private scripts outside the repository:

```bash
export GAUDI_SHELL_CUSTOM="$HOME/.config/gaudi-shell/custom"
```

Or load several custom directories:

```bash
export GAUDI_SHELL_CUSTOM_PATHS="$GAUDI_SHELL/components/custom:$HOME/.config/gaudi-shell/private"
```

Set `GAUDI_SHELL_CUSTOM` or `GAUDI_SHELL_CUSTOM_PATHS` before sourcing the Bash or Zsh adapter. Custom scripts should stay shell-portable if you use both Bash and Zsh; branch on `$GAUDI_SHELL_CURRENT` when behavior needs to differ.

## Commands

```bash
gshell show                          # list all currently enabled components
gshell show aliases                  # list all available aliases (enabled and disabled)
gshell show plugins                  # list all available plugins
gshell show completions              # list all available completions
gshell show aliases enabled          # list only enabled aliases

gshell enable alias git              # enable the git aliases
gshell enable plugin fzf nvm sudo    # enable multiple plugins at once
gshell enable completion docker      # enable docker completion
gshell enable alias all              # enable all aliases

gshell disable plugin nvm            # disable the nvm plugin
gshell disable alias all             # disable all aliases

gshell help aliases                  # show help for enabled aliases
gshell help plugins                  # show functions defined by enabled plugins

gshell search ruby                   # find components matching "ruby"
gshell search git -chruby            # search for git, exclude chruby
gshell search docker --enable        # search and enable all matches

gshell profile save work             # save current enabled components as "work" profile
gshell profile load minimal          # disable everything, then enable from "minimal" profile
gshell profile list                  # list saved profiles
gshell profile rm old-setup          # delete a saved profile

gshell backup                        # back up enabled components to a file
gshell restore                       # re-enable components from backup (also reads older `gaudi enable ...` backups)

gshell doctor                        # diagnostic reload with logging (shows all levels)
gshell doctor errors                 # show only error-level logs
gshell doctor warnings               # show error + warning logs

gshell update                        # update gaudi-shell to latest stable tag
gshell update dev                    # update to the development branch ($GAUDI_SHELL_DEVELOPMENT_BRANCH on $GAUDI_SHELL_REMOTE)

gshell version                       # show version, git SHA, and shell type
gshell reload                        # re-source your shell profile
gshell restart                       # re-exec the shell (stronger than reload)
```

`gshell update dev` targets `origin/main` unless `GAUDI_SHELL_DEVELOPMENT_BRANCH` is set.

## Components

gaudi-shell ships with 71 plugins, 39 alias sets, and 62 completions.

### Plugins

Plugins add new shell functions, behaviors, and integrations:

- **sudo** -- press Escape twice to toggle `sudo` at the beginning of the current command (native bash + zsh)
- **fzf** -- fuzzy finder integration
- **nvm** -- Node version manager (lazy-loaded for fast startup)
- **pyenv** -- Python version management (lazy-loaded for fast startup)
- **extract** -- extract any archive format with a single command
- **cmd-returned-notify** -- terminal bell (BEL) when a long-running command finishes
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
- **gaudi-shell** -- completion for the `gshell` command itself

The bundled completions are bash completions. Under zsh the adapter turns bash's `complete` builtin into a no-op, so only the `gshell` completion, which has a native zsh implementation, is active there.

## Profiles

Profiles let you save, switch between, and share complete component configurations:

```bash
gshell profile save mysetup         # save current enabled components
gshell profile load mysetup         # disable all, re-enable from profile
gshell profile list                 # list saved profiles with component counts
gshell profile rm mysetup           # delete a profile
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

The `duration` segment of the gaudi theme displays how long the last command took. Enable the tracking with:

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
$ gshell search ruby
plugins:      chruby  ruby

$ gshell search docker -machine
aliases:      docker  docker-compose
plugins:      boot2docker  docker  docker-compose
completions:  docker  docker-compose

$ gshell search git --enable    # search and enable all matches
```

Terms are matched case-sensitively against component names and descriptions. Prefix a term with `-` to exclude it. Use `@` for exact match. Add `--enable` or `--disable` to act on results.

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
gshell backup    # writes to $GAUDI_SHELL/tmp/enabled.gaudi-shell.backup
gshell restore   # re-enables from the backup file (validates entries)
```

The backup is a list of `gshell enable <type> <name>` lines. `gshell restore` also accepts backups written before the command was renamed, which used `gaudi enable ...` lines.

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
