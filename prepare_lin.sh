#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_lin.sh
#  CONTENT: Generate bundle for Linux.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

echo "Creating Linux bundle for ${TRAVIS_SMALLTALK_VERSION}..."
BUNDLE_NAME="${TARGET_NAME}-Linux"
BUNDLE_DESCRIPTION="${SQUEAK_VERSION} #${SQUEAK_UPDATE} VM ${VM_VERSION} (${IMAGE_BITS} bit)"
BUNDLE_DIR="${BUILD_DIR}/${BUNDLE_NAME}"
VM_DIR="${BUNDLE_DIR}/bin"
SHARED_DIR="${BUNDLE_DIR}/shared"

TARGET_TARGZ="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.tar.gz"
TARGET_ZIP="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.zip"

echo "...creating directories..."
mkdir "${BUNDLE_DIR}" "${VM_DIR}" "${SHARED_DIR}"

echo "...copying Linux VM..."
cp -R "${TMP_DIR}/${VM_LIN}/lib/squeak/"*/ "${VM_DIR}"

echo "...copying image files into bundle..."
cp "${TMP_DIR}/Squeak.image" "${SHARED_DIR}/${IMAGE_NAME}.image"
cp "${TMP_DIR}/Squeak.changes" "${SHARED_DIR}/${IMAGE_NAME}.changes"
cp "${TMP_DIR}/"*.sources "${SHARED_DIR}/"
cp "${RELEASE_NOTES_DIR}" "${SHARED_DIR}/"

echo "...merging template..."
cp "${LIN_TEMPLATE_DIR}/squeak.sh" "${BUNDLE_DIR}/"

echo "...setting permissions..."
chmod +x "${VM_DIR}/squeak"

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
