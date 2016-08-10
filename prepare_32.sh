#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation (32-bit)
#  FILE:    prepare.sh
#  CONTENT: Generate 32-bit bundles such as the All-in-One.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

readonly ECHO_BIT="32"
readonly IMAGE_URL="${FILES_BASE}${TRAVIS_SMALLTALK_VERSION}.zip"
readonly VM_BASE="${FILES_BASE}"

readonly VM_ARM="vm-armv6"
readonly VM_LIN="vm-linux"
readonly VM_MAC="vm-macos"
readonly VM_WIN="vm-win"

echo "Preparing Squeak (${ECHO_BIT}-bit)..."

echo "...downloading and extracting image, changes, and sources..."
curl -f -s --retry 3 -o "${TMP_DIR}/base.zip" "${IMAGE_URL}"
unzip -q "${TMP_DIR}/base.zip" -d "${TMP_DIR}/"
mv "${TMP_DIR}/"*.image "${TMP_DIR}/Squeak.image"
mv "${TMP_DIR}/"*.changes "${TMP_DIR}/Squeak.changes"

echo "...downloading and extracting Mac OS VM..."
curl -f -s --retry 3 -o "${TMP_DIR}/${VM_MAC}.zip" "${VM_BASE}/${VM_MAC}.zip"
unzip -q "${TMP_DIR}/${VM_MAC}.zip" -d "${TMP_DIR}/${VM_MAC}"

echo "...launching, updating, and configuring Squeak..."
"${TMP_DIR}/${VM_MAC}/CogSpur.app/Contents/MacOS/Squeak" "-exitonwarn" "${TMP_DIR}/Squeak.image" "${SCRIPTS_DIR}/update.st"
source "${TMP_DIR}/version.sh"

echo "...done."

echo "Creating All-in-one bundle (${ECHO_BIT}-bit)..."
readonly IMAGE_NAME="${SQUEAK_VERSION}-${SQUEAK_UPDATE}-${IMAGE_BITS}bit"
readonly BUNDLE_NAME="${SQUEAK_VERSION}-${SQUEAK_UPDATE}-${VM_VERSION}-${IMAGE_BITS}bit-All-in-One"
readonly BUNDLE_DESCRIPTION="${SQUEAK_VERSION} #${SQUEAK_UPDATE} VM ${VM_VERSION} (${IMAGE_BITS} bit)"
readonly APP_NAME="${BUNDLE_NAME}.app"
readonly APP_DIR="${BUILD_DIR}/${APP_NAME}"
readonly CONTENTS_DIR="${APP_DIR}/Contents"
readonly RESOURCES_DIR="${CONTENTS_DIR}/Resources"

readonly VM_ARM_TARGET="${CONTENTS_DIR}/Linux-ARM"
readonly VM_LIN_TARGET="${CONTENTS_DIR}/Linux-i686"
readonly VM_MAC_TARGET="${CONTENTS_DIR}/MacOS"
readonly VM_WIN_TARGET="${CONTENTS_DIR}/Win32"

readonly TARGET_TARGZ="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.tar.gz"
readonly TARGET_ZIP="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.zip"

mv "${TMP_DIR}/${VM_MAC}/CogSpur.app" "${APP_DIR}"

echo "...copying images files into bundle..."
cp "${TMP_DIR}/Squeak.image" "${RESOURCES_DIR}/${IMAGE_NAME}.image"
cp "${TMP_DIR}/Squeak.changes" "${RESOURCES_DIR}/${IMAGE_NAME}.changes"
cp "${TMP_DIR}/"*.sources "${RESOURCES_DIR}"

echo "...downloading and extracting VMs for Linux, Linux (ARMv6), and Windows..."
# ARMv6
curl -f -s --retry 3 -o "${TMP_DIR}/${VM_ARM}.zip" "${VM_BASE}/${VM_ARM}.zip"
unzip -q "${TMP_DIR}/${VM_ARM}.zip" -d "${TMP_DIR}/${VM_ARM}"
mv "${TMP_DIR}/${VM_ARM}" "${VM_ARM_TARGET}"
# Linux 
curl -f -s --retry 3 -o "${TMP_DIR}/${VM_LIN}.zip" "${VM_BASE}/${VM_LIN}.zip"
unzip -q "${TMP_DIR}/${VM_LIN}.zip" -d "${TMP_DIR}/${VM_LIN}"
mv "${TMP_DIR}/${VM_LIN}" "${VM_LIN_TARGET}"
# Windows
curl -f -s --retry 3 -o "${TMP_DIR}/${VM_WIN}.zip" "${VM_BASE}/${VM_WIN}.zip"
unzip -q "${TMP_DIR}/${VM_WIN}.zip" -d "${TMP_DIR}/${VM_WIN}"
mv "${TMP_DIR}/${VM_WIN}" "${VM_WIN_TARGET}"

echo "...merging template..."
cp "${TEMPLATE_DIR}/squeak.bat" "${BUILD_DIR}/"
cp "${TEMPLATE_DIR}/squeak.sh" "${BUILD_DIR}/"
cp -r "${TEMPLATE_DIR}/Squeak.app/Contents/Library" "${CONTENTS_DIR}/"
cp "${TEMPLATE_DIR}/Squeak.app/Contents/Info.plist" "${CONTENTS_DIR}/"
cp "${TEMPLATE_DIR}/Squeak.app/Contents/squeak.sh" "${CONTENTS_DIR}/"
cp "${TEMPLATE_DIR}/Squeak.app/Contents/Win32/Squeak.ini" "${VM_WIN_TARGET}/"

echo "...setting permissions..."
chmod +x "${VM_ARM_TARGET}/squeak" "${VM_LIN_TARGET}/squeak" "${VM_MAC_TARGET}/Squeak" "${VM_WIN_TARGET}/Squeak.exe"

echo "...applying various templates (squeak.sh, Info.plist, etc)..."
# squeak.bat launcher
sed -i ".bak" "s/%APP_NAME%/${APP_NAME}/g" "${BUILD_DIR}/squeak.bat"
rm -f "${BUILD_DIR}/squeak.bat.bak"
# squeak.sh launcher
sed -i ".bak" "s/%APP_NAME%/${APP_NAME}/g" "${BUILD_DIR}/squeak.sh"
rm -f "${BUILD_DIR}/squeak.sh.bak"
# Info.plist
sed -i ".bak" "s/%CFBundleGetInfoString%/${BUNDLE_DESCRIPTION}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%VERSION%/${SQUEAK_VERSION}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%CFBundleIdentifier%/org.squeak.${SQUEAK_VERSION//./}.${IMAGE_BITS}.All-in-One/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${CONTENTS_DIR}/Info.plist"
rm -f "${CONTENTS_DIR}/Info.plist.bak"
# squeak.sh
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${CONTENTS_DIR}/squeak.sh"
rm -f "${CONTENTS_DIR}/squeak.sh.bak"
# Squeak.ini (consistent with contents in Info.plist)
sed -i ".bak" "s/%VERSION%/${BUNDLE_DESCRIPTION}/g" "${VM_WIN_TARGET}/Squeak.ini"
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${VM_WIN_TARGET}/Squeak.ini"
rm -f "${VM_WIN_TARGET}/Squeak.ini.bak"

# Signing the Mac OS application
echo "...signing the bundle..."
codesign -s "${SIGN_IDENTITY}" --force --deep --verbose "${APP_DIR}"

echo "...compressing the bundle..."
pushd "${BUILD_DIR}" > /dev/null
# tar czf "${TARGET_TARGZ}" "./"
zip -q -r "${TARGET_ZIP}" "./"
popd > /dev/null

echo "...uploading to files.squeak.org..."
# curl -T "${TARGET_TARGZ}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"
curl -T "${TARGET_ZIP}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"

echo "...done."


# echo "Creating Linux bundle (${ECHO_BIT}-bit)..."
# readonly LIN_BUILD_DIR="${TRAVIS_BUILD_DIR}/build_lin"
# readonly LIN_BUNDLE_NAME="${IMAGE_NAME}-${VM_VERSION}"
# readonly LIN_TARGET_TARGZ="${TRAVIS_BUILD_DIR}/${LIN_BUNDLE_NAME}.tar.gz"
# readonly LIN_VM_ARM_TARGET="${LIN_BUILD_DIR}/${LIN_BUNDLE_NAME}/Linux-ARM"
# readonly LIN_VM_LIN_TARGET="${LIN_BUILD_DIR}/${LIN_BUNDLE_NAME}/Linux-i686"
# readonly LIN_RESOURCES_DIR="${LIN_BUILD_DIR}/${LIN_BUNDLE_NAME}/Resources"

# mkdir -p "${LIN_BUILD_DIR}/${LIN_BUNDLE_NAME}"

# echo "...copying VM into bundle..."
# mv "${VM_ARM_TARGET}" "${LIN_VM_ARM_TARGET}"
# mv "${VM_LIN_TARGET}" "${LIN_VM_LIN_TARGET}"

# echo "...copying images files into bundle..."
# cp "${TMP_DIR}/Squeak.image" "${LIN_RESOURCES_DIR}/${IMAGE_NAME}.image"
# cp "${TMP_DIR}/Squeak.changes" "${LIN_RESOURCES_DIR}/${IMAGE_NAME}.changes"
# cp "${TMP_DIR}/"*.sources "${LIN_RESOURCES_DIR}"

# echo "...copying startup script..."
# cp "${CONTENTS_DIR}/squeak.sh" "${LIN_BUILD_DIR}/${LIN_BUNDLE_NAME}/squeak.sh"

# echo "...compressing the bundle..."
# pushd "${LIN_BUILD_DIR}" > /dev/null
# tar czf "${LIN_TARGET_TARGZ}" "./"
# popd > /dev/null

# echo "...uploading to files.squeak.org..."
# curl -T "${LIN_TARGET_TARGZ}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"

# echo "...done."





# echo "Creating Mac OS app bundle (${ECHO_BIT}-bit)..."
# readonly MAC_BUILD_DIR="${TRAVIS_BUILD_DIR}/build_mac"
# readonly MAC_BUNDLE_NAME="${IMAGE_NAME}-${VM_VERSION}"
# readonly MAC_TARGET_TARGZ="${TRAVIS_BUILD_DIR}/${MAC_BUNDLE_NAME}.tar.gz"
# readonly MAC_VM_MAC_TARGET="${MAC_BUILD_DIR}/${MAC_BUNDLE_NAME}/Linux-i686"
# readonly MAC_RESOURCES_DIR="${MAC_BUILD_DIR}/${MAC_BUNDLE_NAME}/Resources"

# mkdir "${MAC_BUILD_DIR}"

# echo "...copying VM into bundle..."
# mv "${APP_DIR}" "${MAC_BUILD_DIR}/${MAC_BUNDLE_NAME}.app"


# echo "...copying images files into bundle..."
# cp "${TMP_DIR}/Squeak.image" "${MAC_RESOURCES_DIR}/${IMAGE_NAME}.image"
# cp "${TMP_DIR}/Squeak.changes" "${MAC_RESOURCES_DIR}/${IMAGE_NAME}.changes"
# cp "${TMP_DIR}/"*.sources "${MAC_RESOURCES_DIR}"

# echo "...copying startup script..."
# cp "${CONTENTS_DIR}/squeak.sh" "${MAC_BUILD_DIR}/${MAC_BUNDLE_NAME}/squeak.sh"

# echo "...compressing the bundle..."
# pushd "${MAC_BUILD_DIR}" > /dev/null
# tar czf "${MAC_TARGET_TARGZ}" "./"
# popd > /dev/null

# echo "...uploading to files.squeak.org..."
# curl -T "${MAC_TARGET_TARGZ}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"

# echo "...done."