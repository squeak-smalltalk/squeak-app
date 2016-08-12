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
BUNDLE_NAME="${TARGET_NAME}-Windows"
BUNDLE_DIR="${BUILD_DIR}/${BUNDLE_NAME}"

TARGET_TARGZ="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.tar.gz"
TARGET_ZIP="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.zip"

echo "...creating directories..."
mkdir "${BUNDLE_DIR}"

echo "...copying Windows VM..."
cp -R "${TMP_DIR}/${VM_WIN}/" "${BUNDLE_DIR}"

echo "...copying image files into bundle..."
cp "${TMP_DIR}/Squeak.image" "${BUNDLE_DIR}/${IMAGE_NAME}.image"
cp "${TMP_DIR}/Squeak.changes" "${BUNDLE_DIR}/${IMAGE_NAME}.changes"
cp "${TMP_DIR}/"*.sources "${BUNDLE_DIR}/"
cp -R "${RELEASE_NOTES_DIR}" "${BUNDLE_DIR}/"

echo "...merging template..."
cp "${WIN_TEMPLATE_DIR}/squeak.bat" "${BUNDLE_DIR}/"
cp "${WIN_TEMPLATE_DIR}/Squeak.ini" "${BUNDLE_DIR}/"

echo "...setting permissions..."
chmod +x "${BUNDLE_DIR}/Squeak.exe"

echo "...applying various patches..."
# Squeak.ini
sed -i ".bak" "s/%VERSION%/${BUNDLE_DESCRIPTION}/g" "${BUNDLE_DIR}/Squeak.ini"
rm -f "${BUNDLE_DIR}/Squeak.ini.bak"
# Remove .map files from $BUNDLE_DIR
rm -f "${BUNDLE_DIR}/"*.map

echo "...compressing the bundle..."
pushd "${BUILD_DIR}" > /dev/null
# tar czf "${TARGET_TARGZ}" "./"
zip -q -r "${TARGET_ZIP}" "./"
popd > /dev/null

echo "...uploading to files.squeak.org..."
# curl -T "${TARGET_TARGZ}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"
curl -T "${TARGET_ZIP}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"

echo "...done."

# Reset $BUILD_DIR
rm -rf "${BUILD_DIR}" && mkdir "${BUILD_DIR}"
