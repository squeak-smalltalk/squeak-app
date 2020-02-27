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
BUNDLE_NAME_MAC="${IMAGE_NAME}-${VERSION_VM_MACOS}-macOS"
BUNDLE_ID_MAC="org.squeak.$(echo ${SQUEAK_VERSION} | tr '[:upper:]' '[:lower:]')-${IMAGE_BITS}bit"
BUNDLE_TARGET_MAC="${PRODUCT_DIR}/${BUNDLE_NAME_MAC}.dmg"
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
sed -i ".bak" "s/%CFBundleGetInfoString%/${BUNDLE_NAME_MAC}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleIdentifier%/${BUNDLE_ID_MAC}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleName%/${SMALLTALK_NAME}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleShortVersionString%/${SQUEAK_VERSION_NUMBER}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleVersion%/${IMAGE_BITS} bit/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${CONTENTS_DIR}/Info.plist"
rm -f "${CONTENTS_DIR}/Info.plist.bak"

# Signing the macOS application
echo "...signing the bundle..."
codesign_bundle "${APP_DIR}"

echo "...compressing the bundle for macOS..."
TMP_DMG="temp.dmg"
hdiutil create -size 192m -volname "${BUNDLE_NAME_MAC}" -srcfolder "${APP_DIR}" \
    -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -nospotlight "${TMP_DMG}"
DEVICE="$(hdiutil attach -readwrite -noautoopen -nobrowse "${TMP_DMG}" | awk 'NR==1{print$1}')"
VOLUME="$(mount | grep "${DEVICE}" | sed 's/^[^ ]* on //;s/ ([^)]*)$//')"
hdiutil detach "${DEVICE}"
hdiutil convert "${TMP_DMG}" -format UDBZ -imagekey bzip2-level=6 -o "${BUNDLE_TARGET_MAC}"
rm -f "${TMP_DMG}"

if is_deployment_branch; then
  echo "...notarizing the bundle..."
  xcrun altool --notarize-app --primary-bundle-id "${BUNDLE_ID_MAC}" \
      -u "${NOTARIZATION_USER}" -p "${NOTARIZATION_PASSWORD}" \
      -f "${BUNDLE_TARGET_MAC}"
  
  sleep 120 # Wait for Apple to approve the package
  
  echo "...stapling the ticket to bundle..."
  xcrun stapler staple "${BUNDLE_TARGET_MAC}"
fi

echo "...done."

travis_fold end mac_bundle
