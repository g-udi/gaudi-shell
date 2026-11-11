# shellcheck shell=bash

cite about-plugin
about-plugin 'pygmentize instead of cat to terminal if possible'

if command -v pygmentize > /dev/null 2>&1 ; then
  # get the full paths to binaries
  CAT_BIN=$(command -v cat)
  LESS_BIN=$(command -v less)
  # styles: BASH_IT_CCAT_STYLE / BASH_IT_CLESS_STYLE, else the settings CCAT_STYLE / CLESS_STYLE
  _gaudi_pygmentize_style="$(_gaudi_host_setting CCAT_STYLE)"
  BASH_IT_CCAT_STYLE="${BASH_IT_CCAT_STYLE:-${_gaudi_pygmentize_style:-default}}"
  _gaudi_pygmentize_style="$(_gaudi_host_setting CLESS_STYLE)"
  BASH_IT_CLESS_STYLE="${BASH_IT_CLESS_STYLE:-${_gaudi_pygmentize_style:-default}}"
  unset _gaudi_pygmentize_style

  # pigmentize cat and less outputs - call them ccat and cless to avoid that
  # especially cat'ed output in scripts gets mangled with pygemtized meta characters
  ccat()
  {
      about 'runs either pygmentize or cat on each file passed in'
      param '*: files to concatenate (as normally passed to cat)'
      example 'cat mysite/manage.py dir/text-file.txt'
      group 'pygmentize'
      for var;
      do
          pygmentize -f 256 -O style="$BASH_IT_CCAT_STYLE" -g "$var" 2>/dev/null || "$CAT_BIN" "$var";
      done
  }

  cless()
  {
      about 'it pigments the file passed in and passes it to less for pagination'
      param "\$1: the file to paginate with less"
      example 'less mysite/manage.py'
      group 'pygmentize'
      pygmentize -f 256 -O style="$BASH_IT_CLESS_STYLE" -g "$@" | "$LESS_BIN" -R
  }
fi
