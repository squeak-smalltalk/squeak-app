#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_aio.sh
#  CONTENT: Generate the All-in-One bundle.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

echo "Creating All-in-one bundle for ${TRAVIS_SMALLTALK_VERSION}..."
BUNDLE_NAME="${SQUEAK_VERSION}-${SQUEAK_UPDATE}-${VM_VERSION}-${IMAGE_BITS}bit-All-in-One"
BUNDLE_DESCRIPTION="${SQUEAK_VERSION} #${SQUEAK_UPDATE} VM ${VM_VERSION} (${IMAGE_BITS} bit)"
APP_NAME="${BUNDLE_NAME}.app"
APP_DIR="${BUILD_DIR}/${APP_NAME}"
CONTENTS_DIR="${APP_DIR}/Contents"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

VM_LIN_TARGET="${CONTENTS_DIR}/Linux-x86_64"
VM_MAC_TARGET="${CONTENTS_DIR}/MacOS"
VM_WIN_TARGET="${CONTENTS_DIR}/Win32"

TARGET_TARGZ="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.tar.gz"
TARGET_ZIP="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.zip"

echo "...copying VMs into bundle..."
cp -R "${TMP_DIR}/${VM_MAC}/CogSpur.app" "${APP_DIR}"
cp -R "${TMP_DIR}/${VM_LIN}" "${VM_LIN_TARGET}"
cp -R "${TMP_DIR}/${VM_WIN}" "${VM_WIN_TARGET}" 

echo "...copying images files into bundle..."
cp "${TMP_DIR}/Squeak.image" "${RESOURCES_DIR}/${IMAGE_NAME}.image"
cp "${TMP_DIR}/Squeak.changes" "${RESOURCES_DIR}/${IMAGE_NAME}.changes"
cp "${TMP_DIR}/"*.sources "${RESOURCES_DIR}/"

echo "...merging template..."
cp "${AIO_TEMPLATE_DIR}/squeak.bat" "${BUILD_DIR}/"
cp "${AIO_TEMPLATE_DIR}/squeak.sh" "${BUILD_DIR}/"
cp -r "${AIO_TEMPLATE_DIR}/Squeak.app/Contents/Library" "${CONTENTS_DIR}/"
cp "${AIO_TEMPLATE_DIR}/Squeak.app/Contents/Info.plist" "${CONTENTS_DIR}/"

cp "${AIO_TEMPLATE_DIR}/Squeak.app/Contents/squeak_${IMAGE_BITS}.sh" "${CONTENTS_DIR}/squeak.sh"
cp "${AIO_TEMPLATE_DIR}/Squeak.app/Contents/Win32/Squeak.ini" "${VM_WIN_TARGET}/"

echo "...setting permissions..."
chmod +x "${VM_LIN_TARGET}/squeak" "${VM_MAC_TARGET}/Squeak" "${VM_WIN_TARGET}/Squeak.exe"

echo "...applying various templates (squeak.sh, Info.plist, etc)..."
# squeak.bat launcher
sed -i ".bak" "s/%APP_NAME%/${APP_NAME}/g" "${BUILD_DIR}/squeak.bat"
rm -f "${BUILD_DIR}/squeak.bat.bak"
# squeak.sh launcher
sed -i ".bak" "s/%APP_NAME%/${APP_NAME}/g" "${BUILD_DIR}/squeak.sh"
rm -f "${BUILD_DIR}/squeak.sh.bak"
# Info.plist
sed -i ".bak" "s/%CFBundleGetInfoString%/${BUNDLE_DESCRIPTION}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%VERSION%/${SQUEAK_VERSION}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleIdentifier%/org.squeak.${SQUEAK_VERSION//./}.${IMAGE_BITS}.All-in-One/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${CONTENTS_DIR}/Info.plist"
rm -f "${CONTENTS_DIR}/Info.plist.bak"
# squeak.sh
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${CONTENTS_DIR}/squeak.sh"
rm -f "${CONTENTS_DIR}/squeak.sh.bak"
# Squeak.ini (consistent with contents in Info.plist)
sed -i ".bak" "s/%VERSION%/${BUNDLE_DESCRIPTION}/g" "${VM_WIN_TARGET}/Squeak.ini"
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${VM_WIN_TARGET}/Squeak.ini"
rm -f "${VM_WIN_TARGET}/Squeak.ini.bak"

# Signing the macOS application
echo "...signing the bundle..."
codesign -s "${SIGN_IDENTITY}" --force --deep --verbose "${APP_DIR}"

echo "...compressing the bundle..."
pushd "${BUILD_DIR}" > /dev/null
# tar czf "${TARGET_TARGZ}" "./"
zip -q -r "${TARGET_ZIP}" "./"
popd > /dev/null

echo "...uploading to files.squeak.org..."
# curl -T "${TARGET_TARGZ}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"
curl -T "${TARGET_ZIP}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"

echo "...done."
