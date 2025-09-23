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

echo "---- Running CreatePackage.sh -----"

APP_NAME="${PRODUCT_NAME}.app"
PACKAGE_NAME="${PACKAGE_PRODUCT_NAME}.pkg"
PACKAGE_IDENTIFIER="org.raisingthefloor.${PACKAGE_PRODUCT_NAME}Installer.pkg"
INNER_PACKAGE_IDENTIFIER="org.raisingthefloor.${PACKAGE_PRODUCT_NAME}.pkg"

if [[ -z "$INSTALLER_SIGNING_IDENTITY" ]]; then
    # add default installer signing identity if none was provided
    INSTALLER_SIGNING_IDENTITY="3rd Party Mac Developer Installer: Raising the Floor - US Inc. (5AAXYGZ428)"
fi

if [[ -z "$CURRENT_PROJECT_VERSION" ]]; then
    # default from Xcode (to use if no specific build # was included)
    VERSION="${MARKETING_VERSION}";
else
    # passed in by build pipeline
    VERSION="1.${CURRENT_PROJECT_VERSION}";
fi

echo "[pkg] build inner Morphic package component (with scripts)"
pkgbuild --component "${CONFIGURATION_BUILD_DIR}/${APP_NAME}" --identifier "${INNER_PACKAGE_IDENTIFIER}" --version "${VERSION}" --scripts "${SRCROOT}/Morphic/MorphicInstaller/${PACKAGE_PRODUCT_NAME}/Scripts" --install-location /Applications "${SRCROOT}/${INNER_PACKAGE_IDENTIFIER}"

echo "[pkg] build Morphic installer package"
productbuild  --distribution "${SRCROOT}/Morphic/MorphicInstaller/${PACKAGE_PRODUCT_NAME}/Distribution.plist" --package-path "${SRCROOT}" --identifier "${PACKAGE_IDENTIFIER}" --version "${VERSION}" --resources "${SRCROOT}/Morphic/MorphicInstaller/${PACKAGE_PRODUCT_NAME}/Resources" --timestamp --sign "${INSTALLER_SIGNING_IDENTITY}" "${SRCROOT}/${PACKAGE_NAME}"

echo "[pkg] done"
