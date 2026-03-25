# shellcheck shell=bash

cite about-plugin
about-plugin 'SVN helper functions'

rm_svn () {
  about 'Remove ".svn" files from directory'
  group 'SVN'

  if [[ -z "$1" ]]; then
      reference rm_svn
      return
  fi
  find $1 -name .svn -print0 | xargs -0 rm -rf
}

svn_add () {
    about 'Add to svn repo'
    group 'SVN'

    svn status | grep '^\?' | sed -e 's/? *//' | sed -e 's/ /\ /g' | xargs svn add
}
