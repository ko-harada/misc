#!/bin/bash

TMP=/tmp/mklink-$$

mkdir ${TMP}

function create_link() {
	identify -verbose $1 > ${TMP}/identity
	if [[ $? -ne 0 ]]; then
		echo "[$1] ERROR: failed to read EXIF."
		return
	fi

	file=${1##*/}
	DATE=$(cat ${TMP}/identity \
		| grep "exif:DateTime:" \
		| head -n 1 \
		| awk '{ print $2 }' \
		| sed -e 's/:/-/g')
	if [[ -z ${DATE} ]]; then
		echo "	DATE: Not Found. > ${DATE}_${file}"
	else
		echo "	DATE: ${DATE} > ${DATE}_${file}"
	fi

	ln -sf $1 ../links/${DATE}_${file}
}

for file in "$@"
do
	find /media/ko/Windows8_OS/Users/ko/Pictures -iname "${file}" > ${TMP}/files
	line=$(wc -l ${TMP}/files | awk '{ print $1 }')
	if [[ ${line} -eq 0 ]]; then
		echo "Not Found: ${file}"
	elif [[ ${line} -eq 1 ]]; then
		echo "Found: ${file}"
		create_link $(< ${TMP}/files)
 	else
		echo "Hit multiple files: ${file}. Use first one."
		cat ${TMP}/files | sed -e 's/^/\t/'
		create_link $(head -n 1 ${TMP}/files)
	fi
done

rm -rf ${TMP}
