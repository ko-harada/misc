#!/bin/bash

TMP=/tmp/mklink-$$
SEARCH_PATH=/media/ko/Windows8_OS/Users/ko/Pictures

mkdir ${TMP}

function exif_date() {
    echo "identify -verbose $1 > ${TMP}/identity"
	identify -verbose $1 > ${TMP}/identity
	if [[ $? -ne 0 ]]; then
		echo "[$1] ERROR: failed to read EXIF."
		return 1
	fi

    rm -f ${TMP}/exif_date

	datetime=$(cat ${TMP}/identity \
	    | grep "exif:DateTime:" \
	    | head -n 1 \
	    | awk '{print $2,$3}')
    if [[ -n ${datetime} ]]; then
        cat <<- EOS > ${TMP}/exif_date
		datetime="${datetime}"
		timestamp=
		EOS
		cat ${TMP}/exif_date | sed -e 's/^/> /'
		return 0
    fi

	modify=$(cat ${TMP}/identity \
    | grep "date:modify:" \
    | head -n 1 \
    | awk '{ print $2 }')
    timestamp=$(echo ${modify} \
    | awk -F"+" '{print $1}' \
    | sed -e 's/T/ /' -e 's/-/:/g')
    
    if [[ -n "${timestamp}" ]]; then
		cat <<- EOS > ${TMP}/exif_date
		datetime=
		timestamp="${timestamp}"
		EOS
        cat ${TMP}/exif_date | sed -e 's/^/> /'
        return 0
    fi
    return 1
}

function find_original() {
	find ${SEARCH_PATH} -iname "$1" > ${TMP}/files
	line=$(wc -l ${TMP}/files | awk '{ print $1 }')
	if [[ ${line} -eq 0 ]]; then
		echo "Not Found: $1." 1>&2
		return
	elif [[ ${line} -eq 1 ]]; then
		echo "Found: $1" 1>&2
		echo $(< ${TMP}/files)
 	else
		echo "Hit multiple files: $1. Use first one." 1>&2
		cat ${TMP}/files | sed -e 's/^/\t/' 1>&2
		echo $(head -n 1 ${TMP}/files)
	fi
}

function main() {
	for file in "$@"
	do
		echo "${file}: "
		{
			target=$(find_original "${file}")
			if [[ -z ${target} ]]; then
				echo "${file}: Original file not found. use downloaded file."
				target=$(readlink -f ${file})
			fi

			echo "target: ${target}"
        	exif_date ${target}
        	if [[ $? -ne 0 ]]; then
        	    echo "ERROR: could not extract datetime."
        	    continue
        	fi
        	    
        	eval $(< ${TMP}/exif_date)

        	if [[ -n "${timestamp}" ]]; then
        	    echo "exiftool \"-DateTimeOriginal=${timestamp}\" ${target}"
        	    exiftool "-DateTimeOriginal=${timestamp}" ${target}
        	    datetime=${timestamp}
        	fi

        	created=$(echo ${datetime} \
        	| awk '{print $1}' \
        	| sed -e 's/:/-/g')
			echo "created: ${created}"

			echo "ln -sf ${target} ../links/${created}_${file##*/}"
			ln -sf ${target} ../links/${created}_${file##*/}
		} |& sed -e 's/^/\t/'
		echo
	done
}

main "$@"

rm -rf ${TMP}
