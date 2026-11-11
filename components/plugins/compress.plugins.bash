# shellcheck shell=bash
# shellcheck disable=SC2016

cite about-plugin
about-plugin 'Compression tools'

targz () {
  about 'Create a .tar.gz archive, using `zopfli`, `pigz` or `gzip` for compression'
  group 'Compress'

	local size tmpFile="${*%/}.tar";
	tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1;

	size=$(
		stat -f"%z" "${tmpFile}" 2> /dev/null; # OS X `stat`
		stat -c"%s" "${tmpFile}" 2> /dev/null # GNU `stat`
	);

	local cmd="";
	if (( size < 52428800 )) && hash zopfli 2> /dev/null; then
		# the .tar file is smaller than 50 MB and Zopfli is available; use it
		cmd="zopfli";
	else
		if hash pigz 2> /dev/null; then
			cmd="pigz";
		else
			cmd="gzip";
		fi;
	fi;

	echo "Compressing .tar using \`${cmd}\`…";
	"${cmd}" -v "${tmpFile}" || return 1;
	[[ -f "${tmpFile}" ]] && rm "${tmpFile}";
	echo "${tmpFile}.gz created successfully.";
}

gz () {
	about 'Compare original and gzipped file size'
	group 'Compress'

	# ratio is a decimal, so it cannot be an integer (declare -i) variable
	local origsize gzipsize ratio

	origsize=$(wc -c < "$1");
	gzipsize=$(gzip -c "$1" | wc -c);
	if (( origsize == 0 )); then
		echo "gz: $1 is empty" >&2
		return 1
	fi
	ratio=$(echo "$gzipsize * 100 / $origsize" | bc -l);
	printf "orig: %d bytes\n" "$origsize";
	printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio";
}
