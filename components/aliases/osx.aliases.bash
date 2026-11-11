# shellcheck shell=bash

cite about-alias
about-alias 'OSX specific aliases'

case $OSTYPE in
  darwin*) ;;
  *) return 0 ;;
esac

# Get rid of those pesky .DS_Store files recursively
alias dsclean='find . -type f -name .DS_Store -delete'

# Flush your dns cache
alias flush='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'

# Show/hide hidden files in Finder
alias showhidden="defaults write com.apple.finder AppleShowAllFiles TRUE"
alias hidehidden="defaults write com.apple.finder AppleShowAllFiles FALSE"

# Use Finder's Quick Look on a file (^C or space to close)
alias ql='qlmanage -p 2>/dev/null'

# Mute/Unmute the system volume. Plays nice with all other volume settings.
alias mute="osascript -e 'set volume output muted true'"
alias unmute="osascript -e 'set volume output muted false'"
