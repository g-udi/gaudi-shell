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

- **Cross-shell by design**: aliases and plugins are plain bash scripts, and the zsh adapter supplies what they need to load in zsh too. The aliases and most plugins work in both shells; a plugin that depends on a bash-only feature (`PROMPT_COMMAND`, readline bindings, bash completion) works in bash only. Only completions and themes need shell-specific versions.
- **Intuitive component management**: `gshell enable plugin fzf` works the same in bash and zsh. No editing config files, no sourcing order puzzles, no plugin spec syntax to learn.
- **Batteries included**: ships with 71 plugins, 39 alias sets, and 62 completions — curated and ready to use. No need to find and wire up third-party repositories.
- **Profiles**: save your entire setup as a named profile (`gshell profile save work`), switch between configurations (`gshell profile load minimal`), share them across machines.
- **Search**: `gshell search docker` finds every docker-related alias, plugin, and completion in one shot. Add `--enable` to activate all matches.
- **Proven foundation**: built on years of real-world use in [gaudi-bash](https://github.com/g-udi/gaudi-bash) — segment-based prompt theme, priority-sorted loading, diagnostic tooling (`gshell doctor`).

If you're someone who uses both bash and zsh and wants **one consistent experience** instead of maintaining two separate shell configurations — that's what this is for.

## Installation

```bash
git clone https://github.com/g-udi/gaudi-shell.git ~/.gaudi-shell
cd ~/.gaudi-shell
git submodule update --init components/aliases components/completions components/plugins
./setup.sh
```

The aliases, completions and plugins are shared with [gaudi-bash](https://github.com/g-udi/gaudi-bash) and live in their own repositories ([gaudi-bash-aliases](https://github.com/g-udi/gaudi-bash-aliases), [gaudi-bash-completions](https://github.com/g-udi/gaudi-bash-completions), [gaudi-bash-plugins](https://github.com/g-udi/gaudi-bash-plugins)), which gaudi-shell includes as git submodules pinned to a commit. The second command fetches those three; `install.sh` does the clone and this step for you. The other submodules (`bin/bats-*`) are test tools and are only needed to run the test suite. Without the components, `./setup.sh` stops before changing anything and prints the command above.

The setup script backs up your existing shell config (to a `.bak` file, or a timestamped `.bak.<date>` file when a backup already exists, so an earlier backup is never overwritten), appends the gaudi-shell template to it or replaces it (it asks which; `--silent` appends), and enables a sane set of defaults (general aliases, base plugin, system and `gshell` completions). Running it again is safe: a config file that already loads gaudi-shell is left unchanged.

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

### Uninstalling

```bash
~/.gaudi-shell/uninstall.sh
```

The uninstall script takes the gaudi-shell lines (the `# gaudi-shell` marker, the `export GAUDI_SHELL=...` line and the line that sources the adapter) out of your shell config and deletes the install directory. The rest of the config file is kept as it is, including everything you changed since installing; a copy of the file as it was is left next to it (`.before-gaudi-uninstall`). It looks at the file named by `GAUDI_SHELL_PROFILE` (set in a running gaudi-shell session), otherwise at `~/.zshrc`, `~/.bash_profile` and `~/.bashrc`. If none of them loads gaudi-shell it stops without changing anything.

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

Tab completion for `gshell` (and `g`) works in both bash and zsh for all commands, their arguments (`gshell show aliases enabled`), component and profile names, and the `gshell search` flags. Every command returns a non-zero status when it fails, an unknown command included.

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
      components.bash      # Where component files live, listing, link migration
      core.bash            # Core utilities and describe
      enabler.bash         # Enable components (symlink creation with priority)
      disabler.bash        # Disable components (symlink removal)
      doctor.bash          # Diagnostics (gshell doctor)
      generic.bash         # pathmunge and utility helpers
      help.bash            # Help display for components
      profile.bash         # Profile save/load/list/rm
      updater.bash         # Git-based update (stable/dev modes)
      utils.bash           # General utilities (_command_exists, _read_input, etc.)
  adapters/
    bash/init.bash         # Bash adapter — sources gaudi_shell.sh directly
    zsh/init.zsh           # Zsh adapter — sets up compatibility, then sources gaudi_shell.sh
  components/
    aliases/               # Submodule (gaudi-bash-aliases): lib/<name>.aliases.bash, also loaded by zsh
    plugins/               # Submodule (gaudi-bash-plugins): lib/<name>.plugins.bash; most also work in zsh
    completions/           # Submodule (gaudi-bash-completions): lib/<name>.completions.bash (bash completions)
    host/                  # gaudi-shell's own components: the gshell aliases and completion (bash + zsh)
    themes/                # Prompt themes, per shell (ships bash/gaudi, which also runs in zsh)
    enabled/               # Symlinks to enabled components (runtime state): ../<type>/lib/<file> or ../host/<file>
    custom/                # Untracked local scripts loaded after enabled components
  scripts/
    loader.bash            # Loads all enabled components in priority-sorted order
  profiles/                # Saved named configurations
```

The core engine loads libraries from `lib/`, then the loader walks `components/enabled/` and sources every enabled alias, plugin, and completion. Components are enabled and disabled by creating or removing symlinks in the `enabled/` directory, managed through the `gshell enable` and `gshell disable` commands.

A component file is looked up in `components/host/` first (gaudi-shell's own files, tracked in this repository), then in `components/<type>/lib/` (the shared repositories). One helper in `lib/helpers/components.bash` (`_gaudi-shell-component-file`, `_gaudi-shell-component-files`) answers "where is component X" for every command; nothing else spells out those paths. The shared repositories also hold the own files of the other framework that uses them (`gaudi-bash.aliases.bash`, `gaudi-bash.completions.bash`); gaudi-shell never lists, enables, searches or completes those.

### Design Principles

- **Cross-shell**: aliases and plugins are bash scripts that zsh loads through the adapter; plugins built on bash-only features stay bash-only. Only completions and themes need shell-specific implementations.
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

gshell help                          # show the command usage
gshell help aliases                  # show help for enabled aliases
gshell help plugins                  # show functions defined by enabled plugins

gshell search ruby                   # find components matching "ruby"
gshell search git -chruby            # search for git, exclude chruby
gshell search docker --enable        # search and enable all matches

gshell profile save work             # save current enabled components as "work" profile
gshell profile load minimal          # disable everything, then enable from "minimal" profile
gshell profile list                  # list saved profiles
gshell profile rm old-setup          # delete a saved profile

gshell backup                        # record the enabled components (as the profile "backup")
gshell restore                       # re-enable the components of the backup, without disabling anything

gshell doctor                        # diagnostic reload with logging (shows all levels)
gshell doctor errors                 # show only error-level logs
gshell doctor warnings               # show error + warning logs

gshell update                        # update gaudi-shell to latest stable tag
gshell update dev                    # update to the development branch ($GAUDI_SHELL_DEVELOPMENT_BRANCH on $GAUDI_SHELL_REMOTE)
gshell migrate                       # fetch the shared components if missing, repair enabled links of an older layout

gshell version                       # show version, git SHA, and shell type
gshell reload                        # re-source your shell profile
gshell restart                       # re-exec the shell (stronger than reload)
```

`gshell update dev` targets `origin/main` unless `GAUDI_SHELL_DEVELOPMENT_BRANCH` is set.

After checking out the new version, `gshell update` moves the three component submodules to the commits that version pins (`git submodule update --init components/aliases components/completions components/plugins`) and repairs enabled links if the layout changed. It refuses to run when files of the install directory were edited; a component submodule that sits on another commit does not count as an edit. If you update by hand with `git pull`, run the submodule command yourself, or run `gshell migrate`.

### Upgrading from a vendored-components install

Until this layout, the aliases, completions and plugins were files of this repository (`components/<type>/<file>`). They are now submodules (`components/<type>/lib/<file>`), and gaudi-shell's own files moved to `components/host/`, so the enabled links of an older install point at files that are gone. To bring such an install across:

```bash
gshell update     # or: gshell update dev
gshell migrate    # only if the new shell reports components that "point to a missing file"
gshell reload
```

The `gshell update` of the old version checks out the new files and restarts the shell, but knows nothing about submodules: the new shell then reports each enabled component as pointing to a missing file, with `gshell migrate` as the fix. `gshell migrate` fetches the three component submodules and rewrites every enabled link to the new location, keeping its load priority; it prints one line per link and changes nothing when run again. From then on `gshell update` does both steps itself.

The same by hand:

```bash
git -C "$GAUDI_SHELL" pull
git -C "$GAUDI_SHELL" submodule update --init components/aliases components/completions components/plugins
gshell migrate
```

Running `./setup.sh` again also migrates the links. Shells are never slowed down by this: the loader only reports dangling links, it does not repair them at start-up.

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

Tab-completion for 61 tools including:

- **git** / **git_flow** / **github-cli** -- Git ecosystem
- **docker** / **docker-compose** -- Docker
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

The `load` command checks the profile before it changes anything: every line must be well formed and name a component that exists. If not, it says what is wrong and nothing is disabled or enabled.

## Command Duration

The `duration` segment of the gaudi theme displays how long the last command took. Enable the tracking with:

```bash
export GAUDI_SHELL_COMMAND_DURATION=true
```

Set it before the line that sources the gaudi-shell adapter. The timer starts when a command is run and is reset once the prompt has been drawn: zsh uses its own `preexec`/`precmd` hooks, bash uses [bash-preexec](https://github.com/rcaloras/bash-preexec) when it is loaded and a `DEBUG` trap plus `PROMPT_COMMAND` otherwise. In plain bash the `DEBUG` trap is installed when gaudi-shell is sourced, so the variable has to be set by then; it replaces a `DEBUG` trap set earlier, and one set later (by a plugin such as `cmd-returned-notify`, for example) replaces the timer's. `gshell doctor` logs whether commands are being timed. The first prompt of a new shell shows no duration.

| Variable | Default | Description |
|---|---|---|
| `COMMAND_DURATION_MIN_SECONDS` | `1` | Minimum seconds before elapsed time is shown |
| `COMMAND_DURATION_PRECISION` | `1` | Decimal digits for sub-second display |

## History

`lib/history.bash` turns on appending to the history file and sets defaults without overriding yours:

- `HISTCONTROL` is set to `ignoredups:ignorespace` only when it is not set already.
- `HISTSIZE` is raised to 10000, and `HISTFILESIZE` (bash) or `SAVEHIST` (zsh) to 20000, when they are lower. Larger values, and unlimited history in bash (a negative value), are kept.
- In zsh, `HISTFILE` is set to `~/.zsh_history` when it is not set, since zsh saves no history without it.

Set your own values before the line that sources the gaudi-shell adapter, or after it.

## Search

Find components by keyword across all types:

```bash
$ gshell search ruby
plugins:      chruby  ruby

$ gshell search docker -machine
aliases:      docker  docker-compose
plugins:      docker  docker-compose
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
gshell backup    # writes the profile "backup": $GAUDI_SHELL/profiles/backup.gaudi-shell
gshell restore   # enables every component listed in it (invalid lines are skipped)
```

The backup is a profile under a reserved name, in the profile format (one `<type> <name>` per line), so `gshell profile list` shows it and `gshell profile save backup` is refused. The difference with a profile is in how it is applied: `gshell restore` only enables what the backup lists, while `gshell profile load backup` first disables everything else.

`gshell restore` still reads a backup written by an older version (`$GAUDI_SHELL/tmp/enabled.gaudi-shell.backup`, with `gshell enable <type> <name>` or `gaudi enable ...` lines) when there is no backup profile yet. It fails when there is no backup at all.

For named, reusable configurations, use profiles instead.

## Releasing

Merging to `main` does not create a release. A release is cut by hand:

1. Open **Actions > CI > Run workflow** on GitHub and pick the `main` branch.
2. Choose which part of the version to raise: `patch`, `minor` or `major`.
3. Once the tests and lint pass, the run tags `main` and publishes a GitHub release.

`gshell update` moves an installation to the latest release tag, and `gshell update dev` to the tip of `main`, so the two only differ once `main` has moved past the last release.

## Contributing

Where a component goes depends on who it is for:

- **Shared components** (anything useful to both gaudi-shell and gaudi-bash: an alias set, a plugin, a completion) are contributed to the shared repositories, under `lib/`: [gaudi-bash-aliases](https://github.com/g-udi/gaudi-bash-aliases), [gaudi-bash-plugins](https://github.com/g-udi/gaudi-bash-plugins), [gaudi-bash-completions](https://github.com/g-udi/gaudi-bash-completions). They must not name a framework: they use the `GAUDI_HOST_*` names described in `lib/helpers/utils.bash`. They reach gaudi-shell when the submodule pin is moved (`git -C components/<type> checkout <commit>`, then commit the new pointer here). Do not edit files inside `components/aliases`, `components/completions` or `components/plugins` in a gaudi-shell checkout: those folders belong to the submodules.
- **gaudi-shell's own components** (files that only make sense here, such as the `gshell` aliases and completion) live in `components/host/` as `<name>.<type>.bash` and are tracked in this repository. A file there wins over a shared file of the same name.
- **Machine-local scripts** go in `components/custom/` (see above) and are not committed.

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
