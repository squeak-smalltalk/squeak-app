#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_bundle_macos_arm.sh
#  CONTENT: Generate bundle for macOS M1 (ARMv8).
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

begin_group "Creating macOS bundle for ${SMALLTALK_VERSION}..."
BUNDLE_NAME_MAC_ARM="${IMAGE_NAME}-${VERSION_VM_MACOS}-${BUNDLE_NAME_MAC_ARM_SUFFIX}"
export_variable "BUNDLE_NAME_MAC_ARM" "${BUNDLE_NAME_MAC_ARM}"
BUNDLE_ID_MAC="org.squeak.$(echo ${SQUEAK_VERSION} | tr '[:upper:]' '[:lower:]')-${IMAGE_BITS}bit"
APP_NAME="${IMAGE_NAME}.app"
APP_PATH="${BUILD_PATH}/${APP_NAME}"
CONTENTS_PATH="${APP_PATH}/Contents"
RESOURCES_PATH="${CONTENTS_PATH}/Resources"
VM_MAC_TARGET="${CONTENTS_PATH}/MacOS"

echo "...copying macOS VM (ARM-based)..."
if is_dir "${TMP_PATH}/${VM_MAC_ARM}/Squeak.app"; then
  cp -R "${TMP_PATH}/${VM_MAC_ARM}/Squeak.app" "${APP_PATH}"
else
  echo "Unable to locate macOS VM." && exit 1
fi

copy_resources "${RESOURCES_PATH}"

echo "...merging template..."
cp "${MAC_TEMPLATE_PATH}/Squeak.app/Contents/Info.plist" "${CONTENTS_PATH}/"
cp "${ICONS_PATH}/${SMALLTALK_NAME}"*.icns "${RESOURCES_PATH}/"
ENGLISH_PATH="${MAC_TEMPLATE_PATH}/Squeak.app/Contents/Resources/English.lproj"
cp "${ENGLISH_PATH}/Credits.rtf" "${RESOURCES_PATH}/English.lproj/"

echo "...setting permissions..."
chmod +x "${VM_MAC_TARGET}/Squeak"

echo "...patching Info.plist..."
# Info.plist
sed -i".bak" "s/%SmalltalkName%/${SMALLTALK_NAME}/g" "${CONTENTS_PATH}/Info.plist"
sed -i".bak" "s/%CFBundleGetInfoString%/${BUNDLE_NAME_MAC_ARM}/g" "${CONTENTS_PATH}/Info.plist"
sed -i".bak" "s/%CFBundleIdentifier%/${BUNDLE_ID_MAC}/g" "${CONTENTS_PATH}/Info.plist"
sed -i".bak" "s/%CFBundleName%/${SMALLTALK_NAME}/g" "${CONTENTS_PATH}/Info.plist"
sed -i".bak" "s/%CFBundleShortVersionString%/${SQUEAK_VERSION_NUMBER}/g" "${CONTENTS_PATH}/Info.plist"
sed -i".bak" "s/%CFBundleVersion%/${IMAGE_BITS} bit/g" "${CONTENTS_PATH}/Info.plist"
sed -i".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${CONTENTS_PATH}/Info.plist"
rm -f "${CONTENTS_PATH}/Info.plist.bak"

if should_codesign; then
  do_codesign "${APP_PATH}" # *.app
fi

compress_into_product_macOS "${APP_PATH}" "${BUNDLE_NAME_MAC_ARM}"
reset_build_dir

end_group
