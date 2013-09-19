#!/usr/bin/env bash

NAME='pccp'
VERS='0.1'

ROOT=`pwd`
cd "`dirname $0`"

LABL="${VERS}-r"`svnversion -n`
DIST="${NAME}-${LABL}"
HOLD="${DIST}-publish"

[[ -d "${DIST}" ]] && rm -rf "${DIST}"
[[ -d "${HOLD}" ]] && rm -rf "${HOLD}"

[[ -d "${ROOT}/${DIST}" ]] && rm -rf "${ROOT}/${DIST}"
[[ -d "${ROOT}/${HOLD}" ]] && rm -rf "${ROOT}/${HOLD}"

mkdir -p "${DIST}"
mkdir -p "${HOLD}"

cp "src/pccp.pl" "${DIST}"
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
