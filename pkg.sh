#!/usr/bin/env bash

if [ ${#} -lt 1 ]; then
	echo "usage:"
	echo "   ${0} version-string"
	exit
fi

function sedpat # escapes all sed search pattern special characters
{ 
	printf $1 | sed -e 's/[]\/()$*.^|[]/\\&/g' 
}
function sedrep # escapes all sed replacement pattern special characters
{ 
	printf $1 | sed -e 's/[\/&]/\\&/g' 
}

NAME="pcp"
VERS="${1}"
DATE="$(date "+%m/%d/%Y %R:%S %Z")"

TOKEN_VERS='##PROGRAMVERSION##'
TOKEN_DATE='##PROGRAMDATE##'

ROOT=`pwd`
cd "`dirname ${0}`"

LABL="${VERS}"

DIST="${NAME}-${LABL}"
HOLD="${DIST}-publish"

[[ -d "${DIST}" ]] && rm -rf "${DIST}"
[[ -d "${HOLD}" ]] && rm -rf "${HOLD}"

[[ -d "${ROOT}/${DIST}" ]] && rm -rf "${ROOT}/${DIST}"
[[ -d "${ROOT}/${HOLD}" ]] && rm -rf "${ROOT}/${HOLD}"

mkdir -p "${DIST}"
mkdir -p "${HOLD}"

cp "src/${NAME}" "${DIST}"
cp "README.md" "${DIST}"
cp "LICENSE" "${DIST}"

cp "README.md" "${HOLD}/README.md-${LABL}"
cp "LICENSE" "${HOLD}/LICENSE-${LABL}"

sed -i "" "s/$(sedpat ${TOKEN_VERS})/$(sedrep ${VERS})/g" "${DIST}/${NAME}"
sed -i "" "s/$(sedpat ${TOKEN_DATE})/$(sedrep ${DATE})/g" "${DIST}/${NAME}"

tar -czvf "${DIST}.tgz" "${DIST}"
zip -r "${DIST}.zip" "${DIST}"

mv "${DIST}.tgz" "${HOLD}"
mv "${DIST}.zip" "${HOLD}"

ln -s `basename "${DIST}.tgz"` "${HOLD}/${NAME}.tgz"
ln -s `basename "${DIST}.zip"` "${HOLD}/${NAME}.zip"

ln -s "README.md-${LABL}" "${HOLD}/README.md"
ln -s "LICENSE-${LABL}" "${HOLD}/LICENSE"

rm -rf "${DIST}"
mv "${HOLD}" "${ROOT}/${DIST}"
cd "${ROOT}"
