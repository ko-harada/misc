#!/bin/bash

TMP=/tmp/tateyoko-$$


function islandscape() {
	file=$1
	geometory=$(identify ${file} | awk '{ print $3 }')
	if [[ $? -ne 0 ]]; then
		echo "[${file}] ERROR: read EXIF failed." 1>&2
		continue
	fi
	width=${geometory%x*}
	height=${geometory#*x}

	if [[ $width -gt $height ]]; then
		echo $file
	fi
}

function isportrait() {
	file=$1
	geometory=$(identify ${file} | awk '{ print $3 }')
	if [[ $? -ne 0 ]]; then
		echo "[${file}] ERROR: read EXIF failed." 1>&2
		continue
	fi
	width=${geometory%x*}
	height=${geometory#*x}

	if [[ $height -gt $width ]]; then
		echo $file
	fi
}

for file in $*
do
	case ${file##*.} in
	JPG|jpg|JPEG|jpeg)
		islandscape ${file}
		;;
	*)
		;;
	esac
done

rm -f ${TMP}
