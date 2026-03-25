#
# sudo — press ESC-ESC to toggle sudo at the beginning of the current command
# Fish-specific (uses commandline builtin)

function __gaudi_sudo_toggle
    set -l buf (commandline)
    if test -z "$buf"
        commandline -r (history | head -1)
        set buf (commandline)
    end

    if string match -q 'sudo *' "$buf"
        commandline -r (string replace -r '^sudo ' '' "$buf")
    else
        commandline -r "sudo $buf"
    end
end

bind \e\e __gaudi_sudo_toggle
