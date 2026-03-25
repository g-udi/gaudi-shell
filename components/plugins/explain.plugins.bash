# shellcheck shell=bash

cite about-plugin
about-plugin 'mankier.com explain function to explain other commands'

explain () {
  about 'explain any bash command via mankier.com manpage API'
  example '$ explain                # interactive mode. Type commands to explain in REPL'
  example '$ explain '"'"'cmd -o | ...'"'"' # one quoted command to explain it.'
  group 'Explain'

  if [[ "$#" -eq 0 ]]; then
    while read  -p "Command: " cmd; do
      curl -Gs "https://www.mankier.com/api/explain/?cols=""$(tput cols)" --data-urlencode "q=$cmd"
    done
    echo "Bye!"
  elif [[ "$#" -eq 1 ]]; then
    curl -Gs "https://www.mankier.com/api/explain/?cols=""$(tput cols)" --data-urlencode "q=$1"
  else
    echo "Usage"
    echo "explain                  interactive mode."
    echo "explain 'cmd -o | ...'   one quoted command to explain it."
  fi
}

