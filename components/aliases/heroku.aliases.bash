# shellcheck shell=bash

cite about-alias
about-alias 'Heroku task abbreviations'

alias hk='heroku'
alias hl='heroku apps'
alias hi='heroku info'
alias ho='heroku open'

# dynos and workers
# hd is hexdump on many systems: alias it only when no such binary is installed
hash hd 2> /dev/null || alias hd='heroku ps'
alias hw='heroku ps'

# rake console
alias hrr='heroku run rake'
alias hcon='heroku run console'

# new and restart
alias hnew='heroku create'
alias hrestart='heroku restart'

# logs
alias hlog='heroku logs'
alias hlogs='heroku logs'

# maint
alias hon='heroku maintenance:on'
alias hoff='heroku maintenance:off'

# heroku configs
alias hc='heroku config'
alias hca='heroku config:set'
alias hcr='heroku config:unset'
