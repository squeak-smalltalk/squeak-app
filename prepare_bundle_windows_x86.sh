#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_bundle_windows.sh
#  CONTENT: Generate bundle for Windows (x86 and x86_64).
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

begin_group "Creating Windows bundle for ${SMALLTALK_VERSION}..."
BUNDLE_NAME_WIN_X86="${IMAGE_NAME}-${VERSION_VM_WIN}-${BUNDLE_NAME_WIN_X86_SUFFIX}"
export_variable "BUNDLE_NAME_WIN_X86" "${BUNDLE_NAME_WIN_X86}"
BUNDLE_PATH="${BUILD_PATH}/${BUNDLE_NAME_WIN_X86}"

echo "...creating directories..."
mkdir -p "${BUNDLE_PATH}"

echo "...copying Windows VM (x86-based)..."
cp -R "${TMP_PATH}/${VM_WIN_X86}/"* "${BUNDLE_PATH}"

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

compress_into_product "${BUNDLE_NAME_WIN_X86}"
reset_build_dir

end_group
