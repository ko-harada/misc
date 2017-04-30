#!/bin/bash

TMP=/tmp/lsimage-$$


function lsimage() {
	file=$1
	identify -verbose ${file} > ${TMP}
	if [[ $? -ne 0 ]]; then
		echo "[${file}] ERROR: read EXIF failed." 1>&2
		continue
	fi

	DATE=$(cat ${TMP} \
		| grep "exif:DateTime:" \
		| head -n 1 \
		| awk '{ print $2 }' \
		| sed -e 's/:/-/g')
	if [[ -z ${DATE} ]]; then
		echo "[${file}] ERROR: There is no \"exif:DateTime:\" information" 1>&2
		continue
	fi
	echo "${DATE} ${file}"
}


function lsmovie() {
	file=$1
	ffprobe ${file} > ${TMP} 2>&1
	if [[ $? -ne 0 ]]; then
		echo "[${file}] ERROR: read Metadata failed." 1>&2
		continue
	fi

	DATE=$(cat ${TMP} \
		| grep "creation_time" \
		| head -n 1 \
		| awk '{ print $3 }')
	if [[ -z ${DATE} ]]; then
		echo "[${file}] ERROR: There is no \"creation_time\" metadata" 1>&2
		continue
	fi

	echo "${DATE} ${file}"
}


for file in $*
do
	case ${file##*.} in
	JPG|jpg|JPEG|jpeg)
		lsimage ${file}
		;;
	*)
		lsmovie ${file}
		;;
	esac
done | awk '
{
	if ($1 in dates) {
		dates[$1] = (dates[$1] ", " $2)
	} else {
		dates[$1] = $2
	}
}
END {
	for (date in dates) {
		print date, ":", dates[date]
	}
}
' | sort

rm -f ${TMP}
