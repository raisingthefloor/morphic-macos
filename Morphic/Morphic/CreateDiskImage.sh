#!/bin/sh

#  Copyright 2020 Raising the Floor - US, Inc.
#
#  Licensed under the New BSD license. You may not use this file except in
#  compliance with this License.
#
#  You may obtain a copy of the License at
#  https://github.com/GPII/universal/blob/master/LICENSE.txt
#
#  The R&D leading to these results received funding from the:
#  * Rehabilitation Services Administration, US Dept. of Education under
#    grant H421A150006 (APCP)
#  * National Institute on Disability, Independent Living, and
#    Rehabilitation Research (NIDILRR)
#  * Administration for Independent Living & Dept. of Education under grants
#    H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
#  * European Union's Seventh Framework Programme (FP7/2007-2013) grant
#    agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
#  * William and Flora Hewlett Foundation
#  * Ontario Ministry of Research and Innovation
#  * Canadian Foundation for Innovation
#  * Adobe Foundation
#  * Consumer Electronics Association Foundation

echo "---- Running CreateDiskImage.sh -----"

MOUNT_PATH="MorphicDiskImage"
APP_NAME="${PRODUCT_NAME}.app"
COMPRESSED_TEMPLATE_PATH="${SRCROOT}/Morphic/${TEMPLATE_NAME}.bz2"
TEMP_FOLDER="Morphic.DiskImage.build"

cd "${CONFIGURATION_TEMP_DIR}"
rm -rf "${TEMP_FOLDER}"
mkdir "${TEMP_FOLDER}" && echo "[dmg] Created folder ${CONFIGURATION_TEMP_DIR}/${TEMP_FOLDER}" || exit
cd "${TEMP_FOLDER}" && echo "[dmg] Working in folder ${TEMP_FOLDER}" || exit

bunzip2 -k "${COMPRESSED_TEMPLATE_PATH}" -c > "${TEMPLATE_NAME}" && echo "[dmg] unzipped ${TEMPLATE_NAME}" || exit
hdiutil attach "${TEMPLATE_NAME}" -noautoopen -quiet -mountpoint "${MOUNT_PATH}" && echo "[dmg] mounted ${TEMPLATE_NAME} to ${MOUNT_PATH}" || exit
ditto "${CONFIGURATION_BUILD_DIR}/${APP_NAME}" "${MOUNT_PATH}/${APP_NAME}" && echo "[dmg] copied ${APP_NAME} to ${MOUNT_PATH}" || exit
hdiutil detach "${MOUNT_PATH}" -quiet -force && echo "[dmg] unmounted ${MOUNT_PATH}" || exit
rm -f "${CONFIGURATION_BUILD_DIR}/${PRODUCT_NAME}.dmg"

# This outputs to the Morphic root in the git repo structure, rather than DerivedData
rm -f "${SRCROOT}/${PRODUCT_NAME}.dmg"
hdiutil convert "${TEMPLATE_NAME}" -quiet -format UDZO -imagekey -zlib-level=9 -o "${SRCROOT}/${PRODUCT_NAME}.dmg" && echo "[dmg] created ${SRCROOT}/${PRODUCT_NAME}.dmg" || exit
cd ..
rm -rf "${TEMP_FOLDER}" && echo "[dmg] cleaned up ${TEMP_FOLDER}" || exit
echo "[dmg] done"
