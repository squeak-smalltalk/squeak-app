#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_aio.sh
#  CONTENT: Generate the All-in-One bundle.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

travis_fold start aio_bundle "Creating All-in-one bundle for ${TRAVIS_SMALLTALK_VERSION}..."
BUNDLE_NAME_AIO="${IMAGE_NAME}-All-in-One"
BUNDLE_ID_AIO="org.squeak.$(echo ${SQUEAK_VERSION} | tr '[:upper:]' '[:lower:]')-aio-${IMAGE_BITS}bit"
APP_NAME="${BUNDLE_NAME_AIO}.app"
APP_DIR="${BUILD_DIR}/${APP_NAME}"
CONTENTS_DIR="${APP_DIR}/Contents"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

VM_ARM_TARGET="${CONTENTS_DIR}/Linux-ARM"
if [[ "${IMAGE_BITS}" == "64" ]]; then
  VM_LIN_TARGET="${CONTENTS_DIR}/Linux-x86_64"
else
  VM_LIN_TARGET="${CONTENTS_DIR}/Linux-i686"
fi
VM_MAC_TARGET="${CONTENTS_DIR}/MacOS"
VM_WIN_TARGET="${CONTENTS_DIR}/Win32"

echo "...copying VMs into bundle..."
cp -R "${TMP_DIR}/${VM_MAC}/Squeak.app" "${APP_DIR}"
if is_32bit; then
  cp -R "${TMP_DIR}/${VM_ARM6}" "${VM_ARM_TARGET}"
fi
cp -R "${TMP_DIR}/${VM_LIN}" "${VM_LIN_TARGET}"
cp -R "${TMP_DIR}/${VM_WIN}" "${VM_WIN_TARGET}"

copy_resources "${RESOURCES_DIR}"

echo "...merging template..."
cp "${AIO_TEMPLATE_DIR}/squeak.bat" "${BUILD_DIR}/"
cp "${AIO_TEMPLATE_DIR}/squeak.sh" "${BUILD_DIR}/"
cp "${AIO_TEMPLATE_DIR}/Squeak.app/Contents/Info.plist" "${CONTENTS_DIR}/"
cp "${ICONS_DIR}/${SMALLTALK_NAME}"*.icns "${RESOURCES_DIR}/"
ENGLISH_DIR="${AIO_TEMPLATE_DIR}/Squeak.app/Contents/Resources/English.lproj"
if ! is_Squeak_50; then
  cp "${ENGLISH_DIR}/Credits.rtf" "${RESOURCES_DIR}/English.lproj/"
fi
cp "${AIO_TEMPLATE_DIR}/Squeak.app/Contents/Win32/Squeak.ini" "${VM_WIN_TARGET}/"

echo "...setting permissions..."
chmod +x "${VM_LIN_TARGET}/squeak" "${VM_MAC_TARGET}/Squeak" "${VM_WIN_TARGET}/Squeak.exe" \
    "${BUILD_DIR}/squeak.sh" "${BUILD_DIR}/squeak.bat"

echo "...applying various templates (squeak.sh, Info.plist, etc)..."
# squeak.bat launcher
sed -i ".bak" "s/%APP_NAME%/${APP_NAME}/g" "${BUILD_DIR}/squeak.bat"
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${BUILD_DIR}/squeak.bat"
rm -f "${BUILD_DIR}/squeak.bat.bak"
# squeak.sh launcher
sed -i ".bak" "s/%APP_NAME%/${APP_NAME}/g" "${BUILD_DIR}/squeak.sh"
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${BUILD_DIR}/squeak.sh"
sed -i ".bak" "s/%IMAGE_BITS%/${IMAGE_BITS}/g" "${BUILD_DIR}/squeak.sh"
rm -f "${BUILD_DIR}/squeak.sh.bak"
# Info.plist
sed -i ".bak" "s/%SmalltalkName%/${SMALLTALK_NAME}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleGetInfoString%/${BUNDLE_NAME_AIO}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleIdentifier%/${BUNDLE_ID_AIO}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleName%/${SMALLTALK_NAME}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleShortVersionString%/${SQUEAK_VERSION_NUMBER}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleVersion%/${IMAGE_BITS} bit/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${CONTENTS_DIR}/Info.plist"
rm -f "${CONTENTS_DIR}/Info.plist.bak"
# Squeak.ini (consistent with contents in Info.plist)
sed -i ".bak" "s/%WindowTitle%/${WINDOW_TITLE}/g" "${VM_WIN_TARGET}/Squeak.ini"
rm -f "${VM_WIN_TARGET}/Squeak.ini.bak"
# Remove .map files from $VM_WIN_TARGET
rm -f "${VM_WIN_TARGET}/"*.map

# Signing the macOS application
codesign_bundle "${APP_DIR}"

if is_deployment_branch; then
  notarize "${APP_DIR}"
fi

compress "${BUNDLE_NAME_AIO}"

echo "...done."

travis_fold end aio_bundle
