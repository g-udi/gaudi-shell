# shellcheck shell=bash

cite about-alias
about-alias 'Docker abbreviations/aliases'

alias dk='docker'
# List last Docker container
alias dklc='docker ps -l'
# List last Docker container ID
alias dklcid='docker ps -l -q'
alias dklcip='docker inspect -f "{{.NetworkSettings.IPAddress}}" $(docker ps -l -q)'  # Get IP of last Docker container
# List running Docker containers
alias dkps='docker ps'
# List all Docker containers
alias dkpsa='docker ps -a'
# List Docker images
alias dki='docker images'
# Delete all Docker containers
alias dkrmac='docker rm $(docker ps -a -q)'

# Delete all untagged Docker images
case $OSTYPE in
  darwin*|*bsd*|*BSD*)
    alias dkrmui='docker images -q -f dangling=true | xargs docker rmi'
    ;;
  *)
    alias dkrmui='docker images -q -f dangling=true | xargs -r docker rmi'
    ;;
esac

# Enter last container (works with Docker 1.3 and above)
alias dkelc='docker exec -it $(dklcid) bash --login'
alias dkrmflast='docker rm -f $(dklcid)'
alias dkbash='dkelc'
alias dkex='docker exec -it '
alias dkri='docker run --rm -i '
alias dkric='docker run --rm -i -v $PWD:/cwd -w /cwd '
alias dkrit='docker run --rm -it '
alias dkritc='docker run --rm -it -v $PWD:/cwd -w /cwd '

# Added more recent cleanup options from newer docker versions
alias dkip='docker image prune -a -f'
alias dkvp='docker volume prune -f'
alias dksp='docker system prune -a -f'
