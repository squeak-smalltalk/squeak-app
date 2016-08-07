#!/usr/bin/env bash

set -o errexit

[[ -z "${TRAVIS_BUILD_DIR}" ]] && echo "Script needs to run on Travis CI" && exit 1

readonly IMAGE_URL="http://files.squeak.org/base/${TRAVIS_SMALLTALK_VERSION}.zip"
readonly VM_BASE="http://www.mirandabanda.org/files/Cog/VM/stable/"
readonly VM_VERSION="15.27.3397"
readonly TARGET_URL="https://www.hpi.uni-potsdam.de/hirschfeld/artefacts/squeak/"

readonly BUILD_DIR="${TRAVIS_BUILD_DIR}/build"
readonly SCRIPTS_DIR="${TRAVIS_BUILD_DIR}/scripts"
readonly TEMPLATE_DIR="${TRAVIS_BUILD_DIR}/template"
readonly TMP_DIR="${TRAVIS_BUILD_DIR}/tmp"

readonly VM_ARM="cogspurlinuxhtARM-${VM_VERSION}.tgz"
readonly VM_LIN="cogspurlinuxht-${VM_VERSION}.tgz"
readonly VM_OSX="CogSpur.app-${VM_VERSION}.tgz"
readonly VM_WIN="cogspurwin-${VM_VERSION}.zip"

echo "Make build and tmp directories..."
mkdir "${BUILD_DIR}" "${TMP_DIR}"

echo "Downloading and extracting image, changes, and sources..."
curl -f -s --retry 3 -o "${TMP_DIR}/base.zip" "${IMAGE_URL}"
unzip -q "${TMP_DIR}/base.zip" -d "${TMP_DIR}/"
mv "${TMP_DIR}/"*.image "${TMP_DIR}/Squeak.image"
mv "${TMP_DIR}/"*.changes "${TMP_DIR}/Squeak.changes"
# mv "${TMP_DIR}/"*.sources "${TMP_DIR}"

echo "Downloading and extracting OS X VM..."
curl -f -s --retry 3 -o "${TMP_DIR}/${VM_OSX}" "${VM_BASE}/${VM_OSX}"
tar xzf "${TMP_DIR}/${VM_OSX}" -C "${TMP_DIR}/"

echo "Updating and configuring Squeak..."
"${TMP_DIR}/CogSpur.app/Contents/MacOS/Squeak" "-exitonwarn" "-headless" "${TMP_DIR}/Squeak.image" "${SCRIPTS_DIR}/update.st"

echo "Retrieving image information..."
SQUEAK_VERSION="SqueakUnknownVersion"
SQUEAK_UPDATE="00000"
source "${TMP_DIR}/version.sh"
IMAGE_NAME="${SQUEAK_VERSION}-${SQUEAK_UPDATE}"

readonly BUNDLE_NAME="${IMAGE_NAME}-${VM_VERSION}-All-in-One"
readonly APP_NAME="${BUNDLE_NAME}.app"
readonly APP_DIR="${BUILD_DIR}/${APP_NAME}"
readonly CONTENTS_DIR="${APP_DIR}/Contents"
readonly RESOURCES_DIR="${CONTENTS_DIR}/Resources"

readonly VM_ARM_TARGET="${CONTENTS_DIR}/Linux-ARM"
readonly VM_LIN_TARGET="${CONTENTS_DIR}/Linux-i686"
readonly VM_OSX_TARGET="${CONTENTS_DIR}/MacOS"
readonly VM_WIN_TARGET="${CONTENTS_DIR}/Win32"

readonly TARGET_TARGZ="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.tar.gz"
readonly TARGET_ZIP="${TRAVIS_BUILD_DIR}/${BUNDLE_NAME}.zip"

mv "${TMP_DIR}/CogSpur.app" "${APP_DIR}"

echo "Moving images files into bundle..."
mv "${TMP_DIR}/Squeak.image" "${RESOURCES_DIR}/${IMAGE_NAME}.image"
mv "${TMP_DIR}/Squeak.changes" "${RESOURCES_DIR}/${IMAGE_NAME}.changes"
mv "${TMP_DIR}/"*.sources "${RESOURCES_DIR}"

echo "Downloading and extracting Linux and Windows VMs..."
curl -f -s --retry 3 -o "${TMP_DIR}/${VM_ARM}" "${VM_BASE}/${VM_ARM}"
tar xzf "${TMP_DIR}/${VM_ARM}" -C "${TMP_DIR}/"
mv "${TMP_DIR}/cogspurlinuxhtARM" "${VM_ARM_TARGET}"
curl -f -s --retry 3 -o "${TMP_DIR}/${VM_LIN}" "${VM_BASE}/${VM_LIN}"
tar xzf "${TMP_DIR}/${VM_LIN}" -C "${TMP_DIR}/"
mv "${TMP_DIR}/cogspurlinuxht" "${VM_LIN_TARGET}"
curl -f -s --retry 3 -o "${TMP_DIR}/${VM_WIN}" "${VM_BASE}/${VM_WIN}"
unzip -q "${TMP_DIR}/${VM_WIN}" -d "${TMP_DIR}/"
mv "${TMP_DIR}/cogspurwin" "${VM_WIN_TARGET}"

echo "Merging template..."
mv "${TEMPLATE_DIR}/squeak.bat" "${BUILD_DIR}/"
mv "${TEMPLATE_DIR}/squeak.sh" "${BUILD_DIR}/"
mv "${TEMPLATE_DIR}/Squeak.app/Contents/Library" "${CONTENTS_DIR}/"
mv "${TEMPLATE_DIR}/Squeak.app/Contents/Info.plist" "${CONTENTS_DIR}/"
mv "${TEMPLATE_DIR}/Squeak.app/Contents/squeak.sh" "${CONTENTS_DIR}/"
mv "${TEMPLATE_DIR}/Squeak.app/Contents/Win32/Squeak.ini" "${VM_WIN_TARGET}/"

echo "Setting permissions..."
chmod +x "${VM_ARM_TARGET}/squeak" "${VM_LIN_TARGET}/squeak" "${VM_OSX_TARGET}/Squeak" "${VM_WIN_TARGET}/Squeak.exe"

echo "Updating files..."
# squeak.bat launcher
sed -i ".bak" "s/%APP_NAME%/${APP_NAME}/g" "${BUILD_DIR}/squeak.bat"
rm -f "${BUILD_DIR}/squeak.bat.bak"

# squeak.sh launcher
sed -i ".bak" "s/%APP_NAME%/${APP_NAME}/g" "${BUILD_DIR}/squeak.sh"
rm -f "${BUILD_DIR}/squeak.sh.bak"

# Info.plist
sed -i ".bak" "s/%CFBundleGetInfoString%/${IMAGE_NAME}, SpurVM ${VM_VERSION}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%VERSION%/${SQUEAK_VERSION}/g" "${CONTENTS_DIR}/Info.plist"
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${CONTENTS_DIR}/Info.plist"
rm -f "${CONTENTS_DIR}/Info.plist.bak"

# squeak.sh
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${CONTENTS_DIR}/squeak.sh"
rm -f "${CONTENTS_DIR}/squeak.bak"

# Squeak.ini
sed -i ".bak" "s/%VERSION%/${SQUEAK_VERSION}.image/g" "${VM_WIN_TARGET}/Squeak.ini"
sed -i ".bak" "s/%SqueakImageName%/${IMAGE_NAME}.image/g" "${VM_WIN_TARGET}/Squeak.ini"
rm -f "${VM_WIN_TARGET}/Squeak.ini"

# echo "Signing app bundle..."
unzip -q ./certs/dist.zip -d ./certs
security create-keychain -p travis osx-build.keychain
security default-keychain -s osx-build.keychain
security unlock-keychain -p travis osx-build.keychain
security import ./certs/dist.cer -k ~/Library/Keychains/osx-build.keychain -T /usr/bin/codesign
security import ./certs/dist.p12 -k ~/Library/Keychains/osx-build.keychain -P "${CERT_PASSWORD}" -T /usr/bin/codesign
codesign -s "${SIGN_IDENTITY}" --force --deep --verbose "${APP_DIR}"
security delete-keychain osx-build.keychain

echo "Compressing bundle..."
pushd "${BUILD_DIR}" > /dev/null
tar czf "${TARGET_TARGZ}" "./"
zip -q -r "${TARGET_ZIP}" "./"
popd > /dev/null

echo "Uploading files..."
curl -T "${TARGET_TARGZ}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"
curl -T "${TARGET_ZIP}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"

echo "Done!"
