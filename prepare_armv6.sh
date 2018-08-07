#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_lin.sh
#  CONTENT: Generate bundle for ARMv6.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

travis_fold start armv6_bundle "Creating ARMv6 bundle for ${TRAVIS_SMALLTALK_VERSION}..."
BUNDLE_NAME_ARM="${IMAGE_NAME}-${VERSION_VM_ARMV6}-ARMv6"
BUNDLE_DIR="${BUILD_DIR}/${BUNDLE_NAME_ARM}"
VM_DIR="${BUNDLE_DIR}/bin"
SHARED_DIR="${BUNDLE_DIR}/shared"

echo "...creating directories..."
mkdir "${BUNDLE_DIR}" "${VM_DIR}" "${SHARED_DIR}"

echo "...copying ARMv6 VM..."
cp -R "${TMP_DIR}/${VM_ARM6}/lib/squeak/"*/ "${VM_DIR}"

copy_resources "${SHARED_DIR}"

echo "...merging template..."
cp "${LIN_TEMPLATE_DIR}/squeak.sh" "${BUNDLE_DIR}/"

echo "...setting permissions..."
chmod +x "${VM_DIR}/squeak"

compress "${BUNDLE_NAME_ARM}"

travis_fold end armv6_bundle
