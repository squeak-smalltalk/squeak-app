#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_win.sh
#  CONTENT: Generate bundle for Windows.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

echo "Creating Windows bundle for ${TRAVIS_SMALLTALK_VERSION}..."
BUNDLE_ARCH="Windows"
BUNDLE_NAME="${SQUEAK_VERSION}-${SQUEAK_UPDATE}-${VM_VERSION}-${IMAGE_BITS}bit-${BUNDLE_ARCH}"
BUNDLE_DESCRIPTION="${SQUEAK_VERSION} #${SQUEAK_UPDATE} VM ${VM_VERSION} (${IMAGE_BITS} bit)"
BUNDLE_DIR="${BUILD_DIR}/${BUNDLE_NAME}"
VM_DIR="${BUNDLE_DIR}/bin"
SHARED_DIR="${BUNDLE_DIR}/shared"

TARGET_TARGZ="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.tar.gz"
TARGET_ZIP="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.zip"

echo "...creating directories..."
mkdir "${BUNDLE_DIR}" "${VM_DIR}" "${SHARED_DIR}"

echo "...copying Windows VM..."
cp -R "${TMP_DIR}/${VM_WIN}" "${VM_DIR}"

echo "...copying images files into bundle..."
cp "${TMP_DIR}/Squeak.image" "${SHARED_DIR}/${IMAGE_NAME}.image"
cp "${TMP_DIR}/Squeak.changes" "${SHARED_DIR}/${IMAGE_NAME}.changes"
cp "${TMP_DIR}/"*.sources "${SHARED_DIR}/"
cp "${RELEASE_NOTES_DIR}/"* "${SHARED_DIR}/"

echo "...merging template..."
cp "${WIN_TEMPLATE_DIR}/squeak.bat" "${BUNDLE_DIR}/"
cp "${WIN_TEMPLATE_DIR}/Squeak.ini" "${VM_DIR}/"

echo "...setting permissions..."
chmod +x "${VM_WIN_TARGET}/Squeak.exe"

echo "...applying various patches..."
# squeak.bat launcher
sed -i ".bak" "s/%APP_NAME%/${APP_NAME}/g" "${BUNDLE_DIR}/squeak.bat"
rm -f "${BUILD_DIR}/squeak.bat.bak"
# Squeak.ini
sed -i ".bak" "s/%VERSION%/${BUNDLE_DESCRIPTION}/g" "${VM_DIR}/Squeak.ini"
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${VM_DIR}/Squeak.ini"
rm -f "${VM_DIR}/Squeak.ini.bak"

echo "...compressing the bundle..."
pushd "${BUILD_DIR}" > /dev/null
# tar czf "${TARGET_TARGZ}" "./"
zip -q -r "${TARGET_ZIP}" "./"
popd > /dev/null

echo "...uploading to files.squeak.org..."
# curl -T "${TARGET_TARGZ}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"
curl -T "${TARGET_ZIP}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"

echo "...done."
