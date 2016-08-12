#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_aio.sh
#  CONTENT: Generate the All-in-One bundle.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

echo "Creating All-in-one bundle for ${TRAVIS_SMALLTALK_VERSION}..."
BUNDLE_NAME="${TARGET_NAME}-All-in-One"
APP_NAME="${BUNDLE_NAME}.app"
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
cp -R "${TMP_DIR}/${VM_MAC}/CogSpur.app" "${APP_DIR}"
if is_32bit; then
  cp -R "${TMP_DIR}/${VM_ARM6}" "${VM_ARM_TARGET}"
fi
cp -R "${TMP_DIR}/${VM_LIN}" "${VM_LIN_TARGET}"
cp -R "${TMP_DIR}/${VM_WIN}" "${VM_WIN_TARGET}"

copy_resources "${RESOURCES_DIR}"

echo "...merging template..."
cp "${AIO_TEMPLATE_DIR}/squeak.bat" "${BUILD_DIR}/"
cp "${AIO_TEMPLATE_DIR}/squeak.sh" "${BUILD_DIR}/"
cp -r "${AIO_TEMPLATE_DIR}/Squeak.app/Contents/Library" "${CONTENTS_DIR}/"
cp "${AIO_TEMPLATE_DIR}/Squeak.app/Contents/Info.plist" "${CONTENTS_DIR}/"

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
sed -i ".bak" "s/%CFBundleGetInfoString%/${BUNDLE_DESCRIPTION}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%VERSION%/${SQUEAK_VERSION}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleIdentifier%/org.squeak.${SQUEAK_VERSION//./}.${IMAGE_BITS}.All-in-One/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${CONTENTS_DIR}/Info.plist"
rm -f "${CONTENTS_DIR}/Info.plist.bak"
# Squeak.ini (consistent with contents in Info.plist)
sed -i ".bak" "s/%VERSION%/${BUNDLE_DESCRIPTION}/g" "${VM_WIN_TARGET}/Squeak.ini"
rm -f "${VM_WIN_TARGET}/Squeak.ini.bak"
# Remove .map files from $VM_WIN_TARGET
rm -f "${VM_WIN_TARGET}/"*.map

# Signing the macOS application
echo "...signing the bundle..."
codesign -s "${SIGN_IDENTITY}" --force --deep --verbose "${APP_DIR}"

compress "${BUNDLE_NAME}"
clean
