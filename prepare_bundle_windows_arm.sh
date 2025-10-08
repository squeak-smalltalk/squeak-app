#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_bundle_windows_arm.sh
#  CONTENT: Generate bundle for Windows (ARMv8).
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

begin_group "Creating Windows bundle for ${SMALLTALK_VERSION}..."
BUNDLE_NAME_WIN_ARM="${IMAGE_NAME}-${VERSION_VM_WIN_ARM}-${BUNDLE_NAME_WIN_ARM_SUFFIX}"
export_variable "BUNDLE_NAME_WIN_ARM" "${BUNDLE_NAME_WIN_ARM}"
BUNDLE_PATH="${BUILD_PATH}/${BUNDLE_NAME_WIN_ARM}"

echo "...creating directories..."
mkdir -p "${BUNDLE_PATH}"

echo "...copying Windows VM (ARM-based)..."
cp -R "${TMP_PATH}/${VM_WIN_ARM}/"* "${BUNDLE_PATH}"

copy_resources "${BUNDLE_PATH}"

echo "...merging template..."
cp "${WIN_TEMPLATE_PATH}/Squeak.ini" "${BUNDLE_PATH}/"
cp "${WIN_TEMPLATE_PATH}/Squeak.exe.manifest" "${BUNDLE_PATH}/"
cp "${WIN_TEMPLATE_PATH}/Squeak.exe.manifest" "${BUNDLE_PATH}/SqueakConsole.exe.manifest"

echo "...setting permissions..."
chmod +x "${BUNDLE_PATH}/Squeak.exe"

echo "...applying various patches..."
# Squeak.ini
sed -i".bak" "s/%WindowTitle%/${WINDOW_TITLE}/g" "${BUNDLE_PATH}/Squeak.ini"
rm -f "${BUNDLE_PATH}/Squeak.ini.bak"
# Remove .map files from $BUNDLE_PATH
rm -f "${BUNDLE_PATH}/"*.map

compress_into_product "${BUNDLE_NAME_WIN_ARM}"
reset_build_dir

end_group
