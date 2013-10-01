#!/usr/bin/env bash

NAME='pcp'
VERS='0.2'

ROOT=`pwd`
cd "`dirname $0`"

# use this one to hide any SVN version modifiers (e.g. 'M','S','P')
#LABL="${VERS}-r"`svnversion -n | sed -e 's/^[0-9]*:\([0-9]*\)[^0-9]*/\1/'`

# i like to keep them so that i dont forget to commit any changes
LABL="${VERS}-r"`svnversion -n | sed -e 's/^[0-9]*://'`

DIST="${NAME}-${LABL}"
HOLD="${DIST}-publish"

[[ -d "${DIST}" ]] && rm -rf "${DIST}"
[[ -d "${HOLD}" ]] && rm -rf "${HOLD}"

[[ -d "${ROOT}/${DIST}" ]] && rm -rf "${ROOT}/${DIST}"
[[ -d "${ROOT}/${HOLD}" ]] && rm -rf "${ROOT}/${HOLD}"

mkdir -p "${DIST}"
mkdir -p "${HOLD}"

cp "src/pcp" "${DIST}"
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
