# Gaudi Theme

## Overview

Gaudi is a modular prompt theme, originally built for [gaudi-bash](https://github.com/g-udi/gaudi-bash) and bundled with [gaudi-shell](https://github.com/g-udi/gaudi-shell), where it runs in both bash and zsh. Enable it by setting `GAUDI_SHELL_THEME=gaudi` before the gaudi-shell adapter is sourced. It organizes prompt information into independent **segments** -- small, self-contained scripts that each display a single piece of context (working directory, Git status, language runtime version, cloud profile, and so on).

Key characteristics:

- **Nerd Font support** -- Segments use Nerd Font glyphs by default for icons (e.g., Git branch, Node.js, Docker). A patched Nerd Font must be installed and active in your terminal for symbols to render correctly. Symbol display can be disabled globally with `GAUDI_ENABLE_SYMBOLS=false`, in which case the segment name is shown as a plain-text fallback.
- **Modular segment architecture** -- Every segment lives in its own file under `segments/`. Segments are loaded on demand; only those listed in the three prompt arrays are executed when the prompt renders.
- **Always fresh** -- All three zones, including `GAUDI_PROMPT_ASYNC`, are rendered each time the prompt is drawn, so the prompt never shows stale state (see [Rendering](#rendering)).

## Prompt Layout

The prompt is divided into three configurable zones, each backed by a Bash array:

| Array                 | Position    | Default segments                                              |
|-----------------------|-------------|---------------------------------------------------------------|
| `GAUDI_PROMPT_RIGHT`  | Right-aligned on the first line | `battery`, `time`, `user`, `host`          |
| `GAUDI_PROMPT_LEFT`   | Left-aligned on the first line  | `multiplexer`, `duration`, `cwd`           |
| `GAUDI_PROMPT_ASYNC`  | Appended after LEFT | `scm`, `aws`, `docker`, `node`, `ruby`, `elixir`, `golang`, `angular`, `react`, `php`, `rust`, `haskell`, `julia`, `pyenv`, `elm`, `java`, `package` |

When `GAUDI_SPLIT_PROMPT=true` (the default), the right-aligned and left-aligned zones occupy the same line with the right portion pushed to the terminal edge:

```
                        [battery] [time] [user] [host]   <-- RIGHT (right-aligned)
[multiplexer] [duration] [cwd]  [scm] [node] [docker] ...  <-- LEFT + ASYNC

>> _
```

When `GAUDI_SPLIT_PROMPT=false`, all zones are concatenated on a single line without right-alignment:

```
[battery] [time] [user] [host] [cwd] [scm] [node] [docker] ...

>> _
```

The prompt character (`>>`) appears on the line below, in green. In zsh the right zone is placed in `RPROMPT` instead.

## Configuration

### Global Variables

`GAUDI_SPLIT_PROMPT`, `GAUDI_SPLIT_PROMPT_TWO_LINES` and `GAUDI_ENABLE_SYMBOLS` use Bash default-value assignment (`${VAR=default}`), so any value you set **before** the theme loads takes precedence. The default prefix and suffix are assigned unconditionally when the theme loads.

| Variable | Default | Description |
|----------|---------|-------------|
| `GAUDI_SPLIT_PROMPT` | `true` | When `true`, right-prompt segments are right-aligned on the first line. When `false`, all segments render inline from left to right. |
| `GAUDI_SPLIT_PROMPT_TWO_LINES` | `false` | When `true` (and split prompt is enabled), a newline separates the right and left sections instead of a carriage return on the same line. |
| `GAUDI_ENABLE_SYMBOLS` | `true` | When `true`, Nerd Font glyphs are used for segment icons. When `false`, the segment name is displayed as a plain-text fallback. |
| `GAUDI_PROMPT_DEFAULT_PREFIX` | `" "` (space) | Default string prepended to every segment's content. Individual segments can override this. |
| `GAUDI_PROMPT_DEFAULT_SUFFIX` | `" "` (space) | Default string appended to every segment's content. Individual segments can override this. |

## Rendering

Many segments -- particularly SCM, language runtimes, and cloud profiles -- shell out to external commands (`git`, `node`, `docker`, `aws`, etc.). In gaudi-shell every zone is rendered synchronously when the prompt hook fires, in both bash and zsh, so the prompt always reflects the current state; `GAUDI_PROMPT_ASYNC` is simply the zone appended after `GAUDI_PROMPT_LEFT`. Keep that array short, or disable segments you do not need with their `_SHOW` variable, if the prompt feels slow.

The file-backed background pipeline from gaudi-bash (per-segment cache files, a background worker and an in-place redraw) is not part of the theme. The theme writes nothing to disk when it draws the prompt.

## Available Segments

### Shell Context

| Segment | Description |
|---------|-------------|
| `char` | Prompt character (`>>`). Changes color based on last command exit status (green on success, red on failure). Not part of the default arrays; the built-in prompt character is always green. |
| `continuation` | PS2 continuation prompt character displayed during multi-line input. Configured with `GAUDI_CONTINUATION_PREFIX`, `_SUFFIX`, `_SYMBOL` and `_COLOR`; the `GAUDI_CHAR_*` names it used to share with `char` are still read when the new ones are not set. |
| `cwd` | Current working directory with intelligent path shortening. Changes color when the directory is not writable. Optionally displays file count and total size. |
| `duration` | Execution time of the last command. Requires `GAUDI_SHELL_COMMAND_DURATION=true`. Only appears when the command exceeded a configurable threshold (default: 1 second). |
| `host` | Hostname. Highlights differently when connected via SSH. |
| `jobs` | Indicator for running background jobs. The count is shown once it exceeds a configurable threshold (default: 1). |
| `multiplexer` | Detached tmux and GNU Screen session counts. |
| `separator` | Inserts a newline to split the prompt across multiple lines. |
| `shlvl` | Current shell nesting level (`SHLVL`). Useful for detecting nested shells spawned from editors or nix-shell. Only shown when depth reaches a threshold (default: 2). |
| `system` | System statistics: CPU load, free memory, and disk usage. The theme does not collect them: the segment shows the values of `GAUDI_CPU_LOAD`, `GAUDI_MEMORY_FREE` and `GAUDI_HDD_USAGE` when you set them, and nothing otherwise. |
| `time` | Current time in a configurable format (default: `HH:MM`). |
| `user` | Username. Visibility can be set to `always`, `true` (show if needed or on SSH), `needed`, or `false`. Root users are highlighted in red. |
| `battery` | Battery level and charging status with threshold-based visibility. |
| `vpn` | Indicates when the connection is routed through a VPN. |

### Version Control

| Segment | Description |
|---------|-------------|
| `scm` | Source control management. Shows the current ref plus ahead/behind, stash, merge/rebase state, and Git counters such as `+:N` (staged), `!:N` (changed), `?:N` (untracked), and `x:N` (conflicted). The background changes with repo state: green (clean), orange (staged only), yellow (working tree changes), red (conflicts). Supports Git, Mercurial, Subversion, and Perforce. |

### Languages and Runtimes

| Segment | Description |
|---------|-------------|
| `node` | Node.js version via nvm, nodenv, or the system binary. Shown in directories containing `package.json`, `node_modules`, or `.js` files. |
| `ruby` | Ruby version as reported by `ruby -v`. Shown in directories containing a `Gemfile`, a `Rakefile`, or `.rb` files. |
| `elixir` | Elixir version. Shown in directories containing `mix.exs` or `.ex`/`.exs` files. |
| `golang` | Go version. Shown in directories containing `.go` files, `Godeps`, `glide.yaml` or `Gopkg` files, or located under `GOPATH`. |
| `php` | PHP version. Shown in directories containing PHP project files. |
| `rust` | Rust version and optional toolchain. Shown in directories containing `Cargo.toml` or `.rs` files. |
| `haskell` | Haskell Stack version. Shown in directories containing `stack.yaml`. |
| `julia` | Julia version. Shown in directories containing `.jl` files. |
| `pyenv` | Python version via pyenv. Shown in directories containing Python project markers. |
| `java` | Java version. Shown in directories containing Java project files. |
| `elm` | Elm version. Shown in directories containing `elm-package.json`. |
| `swift` | Swift version via swiftenv. Shown when a local `.swift-version` applies, or always with global display enabled. |
| `dotnet` | .NET SDK version. Shown in directories containing .NET project files. |
| `conda` | Active Conda environment name. |

### Infrastructure

| Segment | Description |
|---------|-------------|
| `aws` | Active AWS CLI profile (`AWS_DEFAULT_PROFILE` / `CURRENT_AWS_PROFILE`). Hidden when set to `default`. |
| `docker` | Docker daemon version. Shown in directories containing `Dockerfile` or `docker-compose.yml`. |
| `dockercompose` | Docker Compose service status with up/down indicators. |
| `gcloud` | Account and project of the active Google Cloud SDK configuration. |
| `kubecontext` | Current Kubernetes context and namespace from `kubectl`. |
| `terraform` | Terraform workspace. Shown in directories containing `.tf` files. |
| `vagrant` | Vagrant machine status. Shown in directories containing a `Vagrantfile`. |
| `nix` | Indicates when running inside a Nix shell environment. |

### Build Tools

| Segment | Description |
|---------|-------------|
| `gradle` | Gradle version. Shown in directories containing Gradle project files. |
| `maven` | Maven version. Shown in directories containing `pom.xml`. |
| `package` | Current package version from `package.json` (NPM). |
| `xcode` | Xcode version on macOS via xcenv. Shown when a local `.xcode-version` applies (`GAUDI_XCODE_SHOW_LOCAL`, default `true`), or always with `GAUDI_XCODE_SHOW_GLOBAL=true`. |

### Frontend Frameworks

| Segment | Description |
|---------|-------------|
| `angular` | Angular version. Shown in directories with `node_modules/angular`. |
| `react` | React version. Shown in directories with `node_modules/react`. |
| `ember` | Ember CLI version. Shown in directories with `ember-cli-build.js` and `node_modules/ember-cli`. |

## Per-Segment Configuration

Every segment follows a consistent configuration pattern using environment variables prefixed with `GAUDI_<SEGMENT>_`. The common variables are:

| Variable Pattern | Purpose | Example |
|------------------|---------|---------|
| `GAUDI_<SEGMENT>_SHOW` | Enable or disable the segment (`true` / `false`). | `GAUDI_NODE_SHOW=false` |
| `GAUDI_<SEGMENT>_COLOR` | ANSI color code (foreground and/or background). | `GAUDI_NODE_COLOR="$GAUDI_YELLOW"` |
| `GAUDI_<SEGMENT>_SYMBOL` | Nerd Font glyph or text displayed before the content. | `GAUDI_NODE_SYMBOL="\ue74e"` |
| `GAUDI_<SEGMENT>_PREFIX` | String prepended to the segment output. | `GAUDI_NODE_PREFIX=" "` |
| `GAUDI_<SEGMENT>_SUFFIX` | String appended to the segment output. | `GAUDI_NODE_SUFFIX=" "` |

Some segments expose additional variables. For example:

- `GAUDI_NODE_DEFAULT_VERSION` -- Hide the segment when the active version matches this value.
- `GAUDI_BATTERY_THRESHOLD` -- Only show battery when the charge is below this percentage.
- `GAUDI_DURATION_MIN_SECONDS` -- Minimum command duration (in seconds) before the segment appears.
- `GAUDI_SCM_FETCH` -- Whether to run `git fetch` automatically.
- `GAUDI_SCM_GIT_*` and `GAUDI_SCM_THEME_*` -- Characters and prefixes of the Git segment (for example `GAUDI_SCM_GIT_AHEAD_CHAR`, `GAUDI_SCM_THEME_PROMPT_DIRTY`). These are defaults: a value set before the adapter is sourced is kept.
- `GAUDI_RUST_SHOW_TOOLCHAIN` -- Display the active Rust toolchain alongside the version.
- `GAUDI_CWD_SHORTEN` -- Intelligently shorten long directory paths.
- `GAUDI_CWD_SUMMARY` -- Append file count and directory size to the path.
- `GAUDI_SHLVL_THRESHOLD` -- Minimum shell depth before the segment appears.

Refer to the header of each segment file in `segments/` for the full list of supported variables.

## Customizing the Prompt

Override the prompt arrays in your shell config (`~/.bash_profile`, `~/.bashrc` or `~/.zshrc`) **after** the line that sources the gaudi-shell adapter; the theme assigns its default arrays when it loads, so earlier values are overwritten. For example, to show only the working directory and Git status on the left, move time to the right, and limit async segments:

```bash
# after sourcing the gaudi-shell adapter

GAUDI_PROMPT_LEFT=(
  cwd
)

GAUDI_PROMPT_RIGHT=(
  time
)

GAUDI_PROMPT_ASYNC=(
  scm
  node
)
```

You can also add segments that are not in the defaults. Any `.bash` file in the `segments/` directory can be referenced by name (without the extension):

```bash
GAUDI_PROMPT_ASYNC=(
  scm
  node
  kubecontext
  terraform
  conda
)
```

To disable a single segment without modifying the arrays, set its `_SHOW` variable:

```bash
GAUDI_DOCKER_SHOW=false
GAUDI_AWS_SHOW=false
```

## Creating Custom Segments

To add a new segment, create a file in the `segments/` directory following this template:

```bash
#!/usr/bin/env bash
#
# My Segment
#
# Brief description of what this segment displays.

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

GAUDI_MYSEGMENT_SHOW="${GAUDI_MYSEGMENT_SHOW=true}"
GAUDI_MYSEGMENT_PREFIX="${GAUDI_MYSEGMENT_PREFIX="$GAUDI_PROMPT_DEFAULT_PREFIX"}"
GAUDI_MYSEGMENT_SUFFIX="${GAUDI_MYSEGMENT_SUFFIX="$GAUDI_PROMPT_DEFAULT_SUFFIX"}"
GAUDI_MYSEGMENT_SYMBOL="${GAUDI_MYSEGMENT_SYMBOL="\\uf111"}"
GAUDI_MYSEGMENT_COLOR="${GAUDI_MYSEGMENT_COLOR="$GAUDI_GREEN"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

gaudi_mysegment () {
  # Early return if disabled
  [[ $GAUDI_MYSEGMENT_SHOW == false ]] && return

  # Check that the relevant tool exists
  gaudi::exists mytool || return

  # Gather information
  local content
  content="$(mytool --version 2>/dev/null)"
  [[ -z "$content" ]] && return

  # Render the section
  gaudi::section \
    "$GAUDI_MYSEGMENT_COLOR" \
    "$GAUDI_MYSEGMENT_PREFIX" \
    "$GAUDI_MYSEGMENT_SYMBOL" \
    "$content" \
    "$GAUDI_MYSEGMENT_SUFFIX"
}
```

Key rules:

1. The filename must match the segment name: `segments/mysegment.bash`.
2. The entry-point function must be named `gaudi_<segment>` (matching the filename).
3. Use `gaudi::exists` to check for external commands and return early if they are not available.
4. Use `gaudi::section` to produce correctly formatted and colored output.
5. Add context detection (check for project files, environment variables, etc.) so the segment only appears when relevant.

Then add the segment name to one of the prompt arrays:

```bash
GAUDI_PROMPT_ASYNC+=( mysegment )
```
