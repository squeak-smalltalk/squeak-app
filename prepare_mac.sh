#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_mac.sh
#  CONTENT: Generate bundle for macOS.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

travis_fold start mac_bundle "Creating macOS bundle for ${TRAVIS_SMALLTALK_VERSION}..."
BUNDLE_NAME="${IMAGE_NAME}-${VERSION_VM_MACOS}-macOS"
APP_NAME="${IMAGE_NAME}.app"
APP_DIR="${BUILD_DIR}/${APP_NAME}"
CONTENTS_DIR="${APP_DIR}/Contents"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
VM_MAC_TARGET="${CONTENTS_DIR}/MacOS"

echo "...copying macOS VM ..."
if is_dir "${TMP_DIR}/${VM_MAC}/Squeak.app"; then
  cp -R "${TMP_DIR}/${VM_MAC}/Squeak.app" "${APP_DIR}"
elif is_dir "${TMP_DIR}/${VM_MAC}/CogSpur.app"; then
  cp -R "${TMP_DIR}/${VM_MAC}/CogSpur.app" "${APP_DIR}"
else
  echo "Unable to locate macOS VM." && exit 1
fi

copy_resources "${RESOURCES_DIR}"

echo "...merging template..."
cp -R "${AIO_TEMPLATE_DIR}/Squeak.app/Contents/Library" "${CONTENTS_DIR}/"
cp "${AIO_TEMPLATE_DIR}/Squeak.app/Contents/Info.plist" "${CONTENTS_DIR}/"
cp "${ICONS_DIR}/${SMALLTALK_NAME}"*.icns "${RESOURCES_DIR}/"
ENGLISH_DIR="${AIO_TEMPLATE_DIR}/Squeak.app/Contents/Resources/English.lproj"
if ! is_Squeak_50; then
  rm -rf "${RESOURCES_DIR}/English.lproj/MainMenu.nib"
  cp -R "${ENGLISH_DIR}/MainMenu.nib" "${RESOURCES_DIR}/English.lproj/MainMenu.nib"
  cp "${ENGLISH_DIR}/Credits.rtf" "${RESOURCES_DIR}/English.lproj/"
fi

echo "...setting permissions..."
chmod +x "${VM_MAC_TARGET}/Squeak"

echo "...patching Info.plist..."
# Info.plist
sed -i ".bak" "s/%SmalltalkName%/${SMALLTALK_NAME}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleGetInfoString%/${BUNDLE_NAME}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleIdentifier%/org.squeak.${SQUEAK_VERSION}.${IMAGE_BITS}.macOS/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleName%/${SMALLTALK_NAME}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleShortVersionString%/${SQUEAK_VERSION_NUMBER}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleVersion%/${IMAGE_BITS} bit/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${CONTENTS_DIR}/Info.plist"
rm -f "${CONTENTS_DIR}/Info.plist.bak"

# Signing the macOS application
echo "...signing the bundle..."
codesign -s "${SIGN_IDENTITY}" --force --deep --verbose "${APP_DIR}"

compress "${BUNDLE_NAME}"

travis_fold end mac_bundle
