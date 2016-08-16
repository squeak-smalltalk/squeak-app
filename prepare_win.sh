#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_win.sh
#  CONTENT: Generate bundle for Windows.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

travis_fold start win_bundle "Creating Windows bundle for ${TRAVIS_SMALLTALK_VERSION}..."
BUNDLE_NAME="${IMAGE_NAME}-${VERSION_VM_WIN}-Windows"
BUNDLE_DIR="${BUILD_DIR}/${BUNDLE_NAME}"

echo "...creating directories..."
mkdir "${BUNDLE_DIR}"

echo "...copying Windows VM..."
cp -R "${TMP_DIR}/${VM_WIN}/" "${BUNDLE_DIR}"

copy_resources "${BUNDLE_DIR}"

echo "...merging template..."
cp "${WIN_TEMPLATE_DIR}/Squeak.ini" "${BUNDLE_DIR}/"

echo "...setting permissions..."
chmod +x "${BUNDLE_DIR}/Squeak.exe"

echo "...applying various patches..."
# Squeak.ini
sed -i ".bak" "s/%VERSION%/${BUNDLE_DESCRIPTION}/g" "${BUNDLE_DIR}/Squeak.ini"
rm -f "${BUNDLE_DIR}/Squeak.ini.bak"
# Remove .map files from $BUNDLE_DIR
rm -f "${BUNDLE_DIR}/"*.map

compress "${BUNDLE_NAME}"

travis_fold end win_bundle
