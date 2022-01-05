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

if [[ "${IMAGE_BITS}" == "64" ]]; then
  VM_MAC_TARGET_NAME="MacOS" # unified binary

  VM_LIN_TARGET_NAME="Linux-x86_64"
  VM_LIN_ARM_TARGET_NAME="Linux-arm64"

  VM_WIN_TARGET_NAME="Windows-x86_64"
  # VM_WIN_ARM_TARGET_NAME="Win32-arm64"
else
  VM_LIN_TARGET_NAME="Linux-i686"
  VM_LIN_ARM_TARGET_NAME="Linux-arm"
  VM_WIN_TARGET_NAME="Windows-x86"
  # VM_WIN_ARM_TARGET_NAME="Win32-arm"
fi

VM_MAC_TARGET="${CONTENTS_PATH}/${VM_MAC_TARGET_NAME}"
VM_LIN_TARGET="${CONTENTS_PATH}/${VM_LIN_TARGET_NAME}"
VM_LIN_ARM_TARGET="${CONTENTS_PATH}/${VM_LIN_ARM_TARGET_NAME}"
VM_WIN_TARGET="${CONTENTS_PATH}/${VM_WIN_TARGET_NAME}"
# VM_WIN_ARM_TARGET="${CONTENTS_PATH}/${VM_WIN_ARM_TARGET_NAME}"

VM_LIN_X86_PATH="${TMP_PATH}/${VM_LIN_X86}"
VM_LIN_ARM_PATH="${TMP_PATH}/${VM_LIN_ARM}"
if should_use_rc_vm; then
  # There is an extra indirection in the OSVM builds on GitHub
  # E.g., vm-linux/sqcogspur32linuxht/...
  pushd ${VM_LIN_X86_PATH}
  VM_LIN_X86_PATH="${VM_LIN_X86_PATH}/$(find * -type d | head -n 1)"
  popd
  pushd ${VM_LIN_ARM_PATH}
  VM_LIN_ARM_PATH="${VM_LIN_ARM_PATH}/$(find * -type d | head -n 1)"
  popd
fi

echo "...copying VMs into bundle..."
if [[ "${IMAGE_BITS}" == "64" ]]; then
  cp -R "${TMP_PATH}/${VM_MAC}/Squeak.app" "${APP_PATH}" # unified binary
  cp -R "${VM_LIN_X86_PATH}" "${VM_LIN_TARGET}"
  cp -R "${VM_LIN_ARM_PATH}" "${VM_LIN_ARM_TARGET}"
  cp -R "${TMP_PATH}/${VM_WIN_X86}" "${VM_WIN_TARGET}"
  # cp -R "${TMP_PATH}/${VM_WIN_ARM}" "${VM_WIN_ARM_TARGET}"
else # 32-bit
  mkdir -p "${APP_PATH}" # no 32-bit macOS .app anymore
  mkdir -p "${CONTENTS_PATH}" # no 32-bit macOS .app anymore
  mkdir -p "${RESOURCES_PATH}" # no 32-bit macOS .app anymore
  mkdir -p "${RESOURCES_PATH}/English.lproj/"
  cp -R "${VM_LIN_X86_PATH}" "${VM_LIN_TARGET}"
  cp -R "${VM_LIN_ARM_PATH}" "${VM_LIN_ARM_TARGET}"
  cp -R "${TMP_PATH}/${VM_WIN_X86}" "${VM_WIN_TARGET}"
  # cp -R "${TMP_PATH}/${VM_WIN_ARM}" "${VM_WIN_ARM_TARGET}"
fi

copy_resources "${RESOURCES_PATH}"

echo "...merging template..."
cp "${WIN_TEMPLATE_PATH}/squeak.bat" "${BUILD_PATH}/"
cp "${LIN_TEMPLATE_PATH}/squeak.sh" "${BUILD_PATH}/"
cp "${MAC_TEMPLATE_PATH}/Squeak.app/Contents/Info.plist" "${CONTENTS_PATH}/"
cp "${ICONS_PATH}/${SMALLTALK_NAME}"*.icns "${RESOURCES_PATH}/"
ENGLISH_PATH="${MAC_TEMPLATE_PATH}/Squeak.app/Contents/Resources/English.lproj"
cp "${ENGLISH_PATH}/Credits.rtf" "${RESOURCES_PATH}/English.lproj/"
cp "${WIN_TEMPLATE_PATH}/Squeak.ini" "${VM_WIN_TARGET}/"

echo "...setting permissions..."
chmod +x \
  "${BUILD_PATH}/squeak.sh" \
  "${BUILD_PATH}/squeak.bat"
if [[ "${IMAGE_BITS}" == "64" ]]; then
  chmod +x \
    "${VM_MAC_TARGET}/Squeak" \
    "${VM_LIN_TARGET}/squeak" \
    "${VM_LIN_ARM_TARGET}/squeak" \
    "${VM_WIN_TARGET}/Squeak.exe"
    # "${VM_WIN_ARM_TARGET}/Squeak.exe"
else # 32-bit
  chmod +x \
    "${VM_LIN_TARGET}/squeak" \
    "${VM_LIN_ARM_TARGET}/squeak" \
    "${VM_WIN_TARGET}/Squeak.exe"
    # "${VM_WIN_ARM_TARGET}/Squeak.exe"
fi

echo "...applying various templates (squeak.sh, Info.plist, etc)..."
# squeak.bat launcher
sed -i".bak" "s/%AIO_APP_NAME%/${APP_NAME}/g" "${BUILD_PATH}/squeak.bat"
sed -i".bak" "s/%AIO_VM_NAME%/${VM_WIN_TARGET_NAME}\\\\Squeak.exe/g" "${BUILD_PATH}/squeak.bat"
sed -i".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${BUILD_PATH}/squeak.bat"
rm -f "${BUILD_PATH}/squeak.bat.bak"
# squeak.sh launcher
sed -i".bak" "s/%VM_NAME%/squeak/g" "${BUILD_PATH}/squeak.sh"
sed -i".bak" "s/%AIO_APP_NAME%/${APP_NAME}/g" "${BUILD_PATH}/squeak.sh"
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

if [[ "${IMAGE_BITS}" == "64" ]]; then
  # No 32-bit macOS VM anymore
  if should_codesign; then
    do_codesign "${APP_PATH}" # *.app
    if should_notarize; then
      do_notarize "${APP_PATH}" # *.app
    fi
  fi
fi

compress_into_product "${BUNDLE_NAME_AIO}"
reset_build_dir

end_group
