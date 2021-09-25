#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_bundle_windows.sh
#  CONTENT: Generate bundle for Windows.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

begin_group "Creating Windows bundle for ${SMALLTALK_VERSION}..."
BUNDLE_NAME_WIN="${IMAGE_NAME}-${VERSION_VM_WIN}-Windows"
export_variable "BUNDLE_NAME_WIN" "${BUNDLE_NAME_WIN}"
BUNDLE_PATH="${BUILD_PATH}/${BUNDLE_NAME_WIN}"

echo "...creating directories..."
mkdir -p "${BUNDLE_PATH}"

echo "...copying Windows VM..."
cp -R "${TMP_PATH}/${VM_WIN}/"* "${BUNDLE_PATH}"

copy_resources "${BUNDLE_PATH}"

echo "...merging template..."
cp "${AIO_TEMPLATE_PATH}/Squeak.app/Contents/Win32/Squeak.ini" "${BUNDLE_PATH}/"

echo "...setting permissions..."
chmod +x "${BUNDLE_PATH}/Squeak.exe"

echo "...applying various patches..."
# Squeak.ini
sed -i".bak" "s/%WindowTitle%/${WINDOW_TITLE}/g" "${BUNDLE_PATH}/Squeak.ini"
rm -f "${BUNDLE_PATH}/Squeak.ini.bak"
# Remove .map files from $BUNDLE_PATH
rm -f "${BUNDLE_PATH}/"*.map

compress_into_product "${BUNDLE_NAME_WIN}"
reset_build_dir

end_group
