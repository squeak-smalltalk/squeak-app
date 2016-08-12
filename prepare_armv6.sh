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
BUNDLE_NAME="${TARGET_NAME}-ARMv6"
BUNDLE_DIR="${BUILD_DIR}/${BUNDLE_NAME}"
VM_DIR="${BUNDLE_DIR}/bin"
SHARED_DIR="${BUNDLE_DIR}/shared"

TARGET_TARGZ="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.tar.gz"
TARGET_ZIP="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.zip"

echo "...creating directories..."
mkdir "${BUNDLE_DIR}" "${VM_DIR}" "${SHARED_DIR}"

echo "...copying Linux VM..."
cp -R "${TMP_DIR}/${VM_ARM6}/lib/squeak/"*/ "${VM_DIR}"

copy_resources "${SHARED_DIR}"

echo "...merging template..."
cp "${LIN_TEMPLATE_DIR}/squeak.sh" "${BUNDLE_DIR}/"

echo "...setting permissions..."
chmod +x "${VM_DIR}/squeak"

compress
upload
clean
