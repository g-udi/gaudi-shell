# shellcheck shell=bash

cite about-plugin
about-plugin 'Helpers to more easily work with Docker'

docker-remove-most-recent-container () {
  about 'Attempt to remove the most recent container from docker ps -a'
  group 'docker'

  docker ps -ql | xargs docker rm
}

docker-remove-most-recent-image () {
  about 'Attempt to remove the most recent image from docker images'
  group 'docker'

  docker images -q | head -1 | xargs docker rmi
}

docker-remove-stale-assets () {
  about 'Attempt to remove exited containers and dangling images'
  group 'docker'

  docker ps --filter status=exited -q | xargs docker rm --volumes
  docker images --filter dangling=true -q | xargs docker rmi
}

docker-enter () {
  about 'Anter the specified docker container using bash'
  group 'docker'
  example 'docker-enter oracle-xe'

  docker exec -it "$@" /bin/bash;
}

docker-remove-images () {
  about 'Attempt to remove images with supplied tags or all if no tags are supplied'
  group 'docker'

  if [[ -z "$1" ]]; then
    docker rmi "$(docker images -q)"
  else
    DOCKER_IMAGES=""
    for IMAGE_ID in "$@"; do DOCKER_IMAGES="$DOCKER_IMAGES\|$IMAGE_ID"; done
    # Find the image IDs for the supplied tags
    ID_ARRAY=( "$(docker images | grep "${DOCKER_IMAGES:2}" | awk "{'print $3'}")" )
    # Strip out duplicate IDs before attempting to remove the image(s)
    docker rmi "$(echo "${ID_ARRAY[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')"
 fi
}

docker-image-dependencies () {
  about 'Attempt to create a Graphiz image of the supplied image ID dependencies'
  group 'docker'

  if hash dot 2>/dev/null; then
    OUT=$(mktemp -t docker-viz-XXXX.png)
    docker images -viz | dot -Tpng > $OUT
    case $OSTYPE in
      linux*)
        xdg-open $OUT
        ;;
      darwin*)
        open $OUT
        ;;
    esac
  else
    >&2 echo "Can't show dependencies; Graphiz is not installed"
  fi
}

docker-runtime-environment () {
  about 'attempt to list the environmental variables of the supplied image ID'
  group 'docker'

  docker run "$@" env
}

docker-archive-content () {
  about 'show the content of the provided Docker image archive'
  group 'docker'
  example 'docker-archive-content images.tar.gz'

  if [[ -n "$1" ]]; then
    tar -xzOf $1 manifest.json | jq '[.[] | .RepoTags] | add'
  fi
}

# Generate aliases for the functions

# Delete most recent (i.e., last) Docker container
alias dkrmlc='docker-remove-most-recent-container'
# Delete all untagged images and exited containers
alias dkrmall='docker-remove-stale-assets'
# Delete most recent (i.e., last) Docker image
alias dkrmli='docker-remove-most-recent-image'
# Delete images for supplied IDs or all if no IDs are passed as arguments
alias dkrmi='docker-remove-images'
# Output a graph of image dependencies using Graphiz
alias dkideps='docker-image-dependencies'
# List environmental variables of the supplied image ID
alias dkre='docker-runtime-environment'