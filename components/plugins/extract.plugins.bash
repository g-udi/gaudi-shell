# shellcheck shell=bash

cite about-plugin
about-plugin 'Universal archive extractor'

extract() {
	about 'Extracts archives of the most common formats'
	param '*: archives to extract'
	group 'extract'

	if [[ -z "${1:-}" ]]; then
		echo "usage: extract <archive>..." >&2
		return 1
	fi

	local archive rc=0
	for archive in "$@"; do
		if [[ ! -f "$archive" ]]; then
			echo "extract: '$archive' is not a file" >&2
			rc=1
			continue
		fi
		case "$archive" in
			*.tar.bz2 | *.tbz2 | *.tbz) tar xjf "$archive" ;;
			*.tar.gz | *.tgz) tar xzf "$archive" ;;
			*.tar.xz | *.txz) tar xJf "$archive" ;;
			*.tar.zst) tar --zstd -xf "$archive" ;;
			*.tar.Z) tar xZf "$archive" ;;
			*.tar) tar xf "$archive" ;;
			*.bz2) bunzip2 "$archive" ;;
			*.gz) gunzip "$archive" ;;
			*.xz) xz --decompress "$archive" ;;
			*.zip | *.war | *.jar) unzip "$archive" ;;
			*.Z) uncompress "$archive" ;;
			*.7z) 7z x "$archive" ;;
			*.rar) unrar x "$archive" ;;
			*.deb) dpkg-deb -x "$archive" "${archive%.deb}" ;;
			*.rpm) rpm2cpio "$archive" | cpio -idm ;;
			*.pax) pax -r -f "$archive" ;;
			*.pkg) pkgutil --expand "$archive" "${archive%.pkg}" ;;
			*)
				echo "extract: unsupported format '$archive'" >&2
				false
				;;
		esac || rc=$?
	done
	return "$rc"
}
