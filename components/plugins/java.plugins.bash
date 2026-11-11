# shellcheck shell=bash

cite about-plugin
about-plugin 'Java and JAR helper functions'

java-link-openjdk () {
  about 'Link Homebrew OpenJDK into the macOS JavaVirtualMachines directory'
  group 'java'

  local source_jdk="${1:-/opt/homebrew/opt/openjdk/libexec/openjdk.jdk}"
  local target_jdk="/Library/Java/JavaVirtualMachines/openjdk.jdk"

  if [[ ! -d "$source_jdk" ]]; then
    printf 'OpenJDK not found at %s\n' "$source_jdk" >&2
    return 1
  fi

  sudo ln -sfn "$source_jdk" "$target_jdk"
}
