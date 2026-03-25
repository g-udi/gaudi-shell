# shellcheck shell=bash
cite about-plugin
about-plugin 'Encoding and decoding functions'

escape () {
    about 'UTF-8-encode a string of Unicode symbols'
    group 'Encode'

    printf "\\\x%s" "$(printf "$@" | xxd -p -c1 -u)";
    if [[ -t 1 ]]; then
        echo "";
    fi;
}

unidecode () {
    about 'Decode \x{ABCD}-style Unicode escape sequences'
    group 'Encode'

    perl -e "binmode(STDOUT, ':utf8'); print \"$*\"";
    if [[ -t 1 ]]; then
        echo "";
    fi;
}
