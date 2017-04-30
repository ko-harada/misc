#!/bin/bash

TMP=/tmp/mvimage-$$

function mvfile() {
	file=$1
	DIR=$2
	if [[ ! -e ${DIR} ]]; then
		# echo "mkdir ${DIR}"
		mkdir ${DIR}
	fi

	if [[ ! -r ${file} ]]; then
		echo "[${file}] ERROR: file not readable."
		return
	fi

	if [[ ! -x ${DIR} ]]; then
		echo "[${file}] ERROR: ${DIR} is not writable."
		return
	fi
	# echo "mv ${file} ${DIR}/"
	mv ${file} ${DIR}/
}


function mvimage() {
	file=$1
	# echo "identify -verbose ${file} > ${TMP}"
	identify -verbose ${file} > ${TMP}
	if [[ $? -ne 0 ]]; then
		echo "[${file}] ERROR: read EXIF failed."
		continue
	fi

	DIR=$(cat ${TMP} \
		| grep "exif:DateTime:" \
		| head -n 1 \
		| awk '{ print $2 }' \
		| sed -e 's/:/-/g' -e 's/-[^-]*$//')
	if [[ -z ${DIR} ]]; then
		echo "[${file}] ERROR: There is no \"exif:DateTime:\" information"
		continue
	fi
	# echo "DIR: ${DIR}"

	mvfile ${file} ${DIR}
}


function mvmovie() {
	file=$1
	ffprobe ${file} > ${TMP} 2>&1
	if [[ $? -ne 0 ]]; then
		echo "[${file}] ERROR: read Metadata failed."
		continue
	fi

	DIR=$(cat ${TMP} \
		| grep "creation_time" \
		| head -n 1 \
		| awk '{ print $3 }' \
		| sed -e 's/-[^-]*$//')
	if [[ -z ${DIR} ]]; then
		echo "[${file}] ERROR: There is no \"creation_time\" metadata"
		continue
	fi

	mvfile ${file} ${DIR}
}


for file in $*
do
	case ${file##*.} in
	JPG|jpg|JPEG|jpeg)
		mvimage ${file}
		;;
	*)
		mvmovie ${file}
		;;
	esac
done

rm -f ${TMP}
