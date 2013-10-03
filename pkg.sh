#!/usr/bin/env bash

if [ $# -lt 2 ]; then
	echo "usage:"
	echo "   $0 program-name program-version"
	exit
fi

NAME="$1"
VERS="$2"
DATE="$(date "+%m/%d/%Y %R:%S %Z")"

TOKEN_NAME='##PROGRAMNAME##'
TOKEN_VERS='##PROGRAMVERSION##'
TOKEN_DATE='##PROGRAMDATE##'

ROOT=`pwd`
cd "`dirname $0`"

# i like to keep them so that i dont forget to commit any changes
LABL="${VERS}"

DIST="${NAME}-${LABL}"
HOLD="${DIST}-publish"

[[ -d "${DIST}" ]] && rm -rf "${DIST}"
[[ -d "${HOLD}" ]] && rm -rf "${HOLD}"

[[ -d "${ROOT}/${DIST}" ]] && rm -rf "${ROOT}/${DIST}"
[[ -d "${ROOT}/${HOLD}" ]] && rm -rf "${ROOT}/${HOLD}"

mkdir -p "${DIST}"
mkdir -p "${HOLD}"

cp "src/$NAME" "${DIST}"
cp "README" "${DIST}"
cp "LICENSE" "${DIST}"

cp "README" "${HOLD}/README-${LABL}"
cp "LICENSE" "${HOLD}/LICENSE-${LABL}"

tar -czvf "${DIST}.tgz" "${DIST}"
zip -r "${DIST}.zip" "${DIST}"

mv "${DIST}.tgz" "${HOLD}"
mv "${DIST}.zip" "${HOLD}"

ln -s `basename "${DIST}.tgz"` "${HOLD}/${NAME}.tgz"
ln -s `basename "${DIST}.zip"` "${HOLD}/${NAME}.zip"

ln -s "README-${LABL}" "${HOLD}/README"
ln -s "LICENSE-${LABL}" "${HOLD}/LICENSE"

rm -rf "${DIST}"
mv "${HOLD}" "${ROOT}/${DIST}"
cd "${ROOT}"
