#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare_bundle_aio.sh
#  CONTENT: Generate the All-in-One bundle.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

begin_group "Creating All-in-one bundle for ${SMALLTALK_VERSION}..."
BUNDLE_NAME_AIO="${IMAGE_NAME}-All-in-One"
export_variable "BUNDLE_NAME_AIO" "${BUNDLE_NAME_AIO}"
BUNDLE_ID_AIO="org.squeak.$(echo ${SQUEAK_VERSION} | tr '[:upper:]' '[:lower:]')-aio-${IMAGE_BITS}bit"
APP_NAME="${BUNDLE_NAME_AIO}.app"
APP_PATH="${BUILD_PATH}/${APP_NAME}"
CONTENTS_PATH="${APP_PATH}/Contents"
RESOURCES_PATH="${CONTENTS_PATH}/Resources"

VM_ARM_TARGET="${CONTENTS_PATH}/Linux-ARM"
if [[ "${IMAGE_BITS}" == "64" ]]; then
  VM_LIN_TARGET="${CONTENTS_PATH}/Linux-x86_64"
else
  VM_LIN_TARGET="${CONTENTS_PATH}/Linux-i686"
fi
VM_MAC_TARGET="${CONTENTS_PATH}/MacOS"
VM_WIN_TARGET="${CONTENTS_PATH}/Win32"

echo "...copying VMs into bundle..."
cp -R "${TMP_PATH}/${VM_MAC}/Squeak.app" "${APP_PATH}"
if is_32bit; then
  cp -R "${TMP_PATH}/${VM_ARM6}" "${VM_ARM_TARGET}"
fi
cp -R "${TMP_PATH}/${VM_LIN}" "${VM_LIN_TARGET}"
cp -R "${TMP_PATH}/${VM_WIN}" "${VM_WIN_TARGET}"

copy_resources "${RESOURCES_PATH}"

echo "...merging template..."
cp "${AIO_TEMPLATE_PATH}/squeak.bat" "${BUILD_PATH}/"
cp "${AIO_TEMPLATE_PATH}/squeak.sh" "${BUILD_PATH}/"
cp "${AIO_TEMPLATE_PATH}/Squeak.app/Contents/Info.plist" "${CONTENTS_PATH}/"
cp "${ICONS_PATH}/${SMALLTALK_NAME}"*.icns "${RESOURCES_PATH}/"
ENGLISH_PATH="${AIO_TEMPLATE_PATH}/Squeak.app/Contents/Resources/English.lproj"
cp "${ENGLISH_PATH}/Credits.rtf" "${RESOURCES_PATH}/English.lproj/"
cp "${AIO_TEMPLATE_PATH}/Squeak.app/Contents/Win32/Squeak.ini" "${VM_WIN_TARGET}/"

echo "...setting permissions..."
chmod +x "${VM_LIN_TARGET}/squeak" "${VM_MAC_TARGET}/Squeak" "${VM_WIN_TARGET}/Squeak.exe" \
    "${BUILD_PATH}/squeak.sh" "${BUILD_PATH}/squeak.bat"

echo "...applying various templates (squeak.sh, Info.plist, etc)..."
# squeak.bat launcher
sed -i".bak" "s/%APP_NAME%/${APP_NAME}/g" "${BUILD_PATH}/squeak.bat"
sed -i".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${BUILD_PATH}/squeak.bat"
rm -f "${BUILD_PATH}/squeak.bat.bak"
# squeak.sh launcher
sed -i".bak" "s/%APP_NAME%/${APP_NAME}/g" "${BUILD_PATH}/squeak.sh"
sed -i".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${BUILD_PATH}/squeak.sh"
sed -i".bak" "s/%IMAGE_BITS%/${IMAGE_BITS}/g" "${BUILD_PATH}/squeak.sh"
rm -f "${BUILD_PATH}/squeak.sh.bak"
# Info.plist
sed -i".bak" "s/%SmalltalkName%/${SMALLTALK_NAME}/g" "${CONTENTS_PATH}/Info.plist"
sed -i".bak" "s/%CFBundleGetInfoString%/${BUNDLE_NAME_AIO}/g" "${CONTENTS_PATH}/Info.plist"
sed -i".bak" "s/%CFBundleIdentifier%/${BUNDLE_ID_AIO}/g" "${CONTENTS_PATH}/Info.plist"
sed -i".bak" "s/%CFBundleName%/${SMALLTALK_NAME}/g" "${CONTENTS_PATH}/Info.plist"
sed -i".bak" "s/%CFBundleShortVersionString%/${SQUEAK_VERSION_NUMBER}/g" "${CONTENTS_PATH}/Info.plist"
sed -i".bak" "s/%CFBundleVersion%/${IMAGE_BITS} bit/g" "${CONTENTS_PATH}/Info.plist"
sed -i".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${CONTENTS_PATH}/Info.plist"
rm -f "${CONTENTS_PATH}/Info.plist.bak"
# Squeak.ini (consistent with contents in Info.plist)
sed -i".bak" "s/%WindowTitle%/${WINDOW_TITLE}/g" "${VM_WIN_TARGET}/Squeak.ini"
rm -f "${VM_WIN_TARGET}/Squeak.ini.bak"
# Remove .map files from $VM_WIN_TARGET
rm -f "${VM_WIN_TARGET}/"*.map

if should_codesign; then
  do_codesign "${APP_PATH}" # *.app
  if should_notarize; then
    do_notarize "${APP_PATH}" # *.app
  fi
fi

compress_into_product "${BUNDLE_NAME_AIO}"
reset_build_dir

end_group
