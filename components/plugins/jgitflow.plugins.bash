# shellcheck shell=bash

cite about-plugin
about-plugin 'Maven jgitflow build helpers'

hotfix-start () {
  about 'Helper function for starting a new hotfix'
  group 'gitflow'

  mvn jgitflow:hotfix-start ${JGITFLOW_MVN_ARGUMENTS}
}

hotfix-finish () {
  about 'Helper function for finishing a hotfix'
  group 'gitflow'

  mvn jgitflow:hotfix-finish -Darguments="${JGITFLOW_MVN_ARGUMENTS}" && git push && git push origin master && git push --tags
}

feature-start () {
  about 'Helper function for starting a new feature'
  group 'gitflow'

  mvn jgitflow:feature-start ${JGITFLOW_MVN_ARGUMENTS}
}

feature-finish () {
  about 'Helper function for finishing a feature'
  group 'gitflow'

  mvn jgitflow:feature-finish ${JGITFLOW_MVN_ARGUMENTS}

  echo -e 'REMEMBER TO CREATE A NEW RELEASE TO DEPLOY THIS FEATURE'
}

release-start () {
  about 'Helper function for starting a new release'
  group 'gitflow'

  mvn jgitflow:release-start ${JGITFLOW_MVN_ARGUMENTS}
}

release-finish () {
  about 'Helper function for finishing a release'
  group 'gitflow'

  mvn jgitflow:release-finish -Darguments="${JGITFLOW_MVN_ARGUMENTS}" && git push && git push origin master && git push --tags
}
