#!/usr/bin/env bash
################################################################################
#  PROJECT: Squeak Bundle Generation
#  FILE:    prepare.sh
#  CONTENT: Generate different bundles such as the All-in-One.
#
#  AUTHORS: Fabio Niephaus, Hasso Plattner Institute, Potsdam, Germany
#           Marcel Taeumel, Hasso Plattner Institute, Potsdam, Germany
################################################################################

set -o errexit

if [[ -z "${TRAVIS_BUILD_DIR}" ]]; then
  echo "Script needs to run on Travis CI"
  exit 1
fi

readonly FILES_BASE="http://files.squeak.org/base"
readonly RELEASE_URL="${FILES_BASE}/${TRAVIS_SMALLTALK_VERSION}"
readonly IMAGE_URL="${RELEASE_URL}/base.zip"
readonly VM_BASE="${RELEASE_URL}"
readonly TARGET_URL="https://www.hpi.uni-potsdam.de/hirschfeld/artefacts/squeak/"

readonly TEMPLATE_DIR="${TRAVIS_BUILD_DIR}/templates"
readonly AIO_TEMPLATE_DIR="${TEMPLATE_DIR}/all-in-one"
readonly LIN_TEMPLATE_DIR="${TEMPLATE_DIR}/linux"
readonly MAC_TEMPLATE_DIR="${TEMPLATE_DIR}/macos"
readonly WIN_TEMPLATE_DIR="${TEMPLATE_DIR}/win"

readonly BUILD_DIR="${TRAVIS_BUILD_DIR}/build"
readonly TMP_DIR="${TRAVIS_BUILD_DIR}/tmp"

readonly RELEASE_NOTES_DIR="${TRAVIS_BUILD_DIR}/release-notes"

readonly VM_LIN="vm-linux"
readonly VM_MAC="vm-macos"
readonly VM_WIN="vm-win"
readonly VM_ARM6="vm-armv6"

# Prepare signing
KEY_CHAIN=macos-build.keychain
unzip -q ./certs/dist.zip -d ./certs
security create-keychain -p travis "${KEY_CHAIN}"
security default-keychain -s "${KEY_CHAIN}"
security unlock-keychain -p travis "${KEY_CHAIN}"
security set-keychain-settings -t 3600 -u "${KEY_CHAIN}"
security import ./certs/dist.cer -k ~/Library/Keychains/"${KEY_CHAIN}" -T /usr/bin/codesign
security import ./certs/dist.p12 -k ~/Library/Keychains/"${KEY_CHAIN}" -P "${CERT_PASSWORD}" -T /usr/bin/codesign

# Create build and temp folders
mkdir "${BUILD_DIR}" "${TMP_DIR}"

echo "...downloading and extracting macOS VM..."
curl -f -s --retry 3 -o "${TMP_DIR}/${VM_MAC}.zip" "${VM_BASE}/${VM_MAC}.zip"
unzip -q "${TMP_DIR}/${VM_MAC}.zip" -d "${TMP_DIR}/${VM_MAC}"

echo "...downloading and extracting Linux VM..."
curl -f -s --retry 3 -o "${TMP_DIR}/${VM_LIN}.zip" "${VM_BASE}/${VM_LIN}.zip"
unzip -q "${TMP_DIR}/${VM_LIN}.zip" -d "${TMP_DIR}/${VM_LIN}"

echo "...downloading and extracting Windows VM..."
curl -f -s --retry 3 -o "${TMP_DIR}/${VM_WIN}.zip" "${VM_BASE}/${VM_WIN}.zip"
unzip -q "${TMP_DIR}/${VM_WIN}.zip" -d "${TMP_DIR}/${VM_WIN}"

function upload() {
    echo "...uploading to files.squeak.org..."
    # curl -T "${TARGET_TARGZ}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"
    curl -T "${TARGET_ZIP}" -u "${DEPLOY_CREDENTIALS}" "${TARGET_URL}"
}

function compress() {
    echo "...compressing the bundle..."
    pushd "${BUILD_DIR}" > /dev/null
    # tar czf "${TARGET_TARGZ}" "./"
    zip -q -r "${TARGET_ZIP}" "./"
    popd > /dev/null
}

function copy_resources() {
    echo "...copying image files into bundle..."
    cp "${TMP_DIR}/Squeak.image" "${1}/${IMAGE_NAME}.image"
    cp "${TMP_DIR}/Squeak.changes" "${1}/${IMAGE_NAME}.changes"
    cp "${TMP_DIR}/"*.sources "${1}/"
    cp -R "${TMP_DIR}/locale" "${1}/"
    cp -R "${RELEASE_NOTES_DIR}" "${1}/"
    if [ "${ETOYS}" == "Squeakland" ]; then
	cp "${TMP_DIR}/*.pr" "${1}/"
	cp -R "${TMP_DIR}/ExampleEtoys" "${1}/"
    fi
}

function clean() {
    echo "...done."
    # Reset $BUILD_DIR
    rm -rf "${BUILD_DIR}" && mkdir "${BUILD_DIR}"
}

# ARMv6 currently only supported on 32-bit
if [[ "${TRAVIS_SMALLTALK_VERSION}" != *"-64" ]]; then
  echo "...downloading and extracting ARMv6 VM..."
  curl -f -s --retry 3 -o "${TMP_DIR}/${VM_ARM6}.zip" "${VM_BASE}/${VM_ARM6}.zip"
  unzip -q "${TMP_DIR}/${VM_ARM6}.zip" -d "${TMP_DIR}/${VM_ARM6}"
fi

source "prepare_image.sh"
source "prepare_aio.sh"
source "prepare_mac.sh"
source "prepare_lin.sh"
source "prepare_win.sh"
if [[ "${TRAVIS_SMALLTALK_VERSION}" != *"-64" ]]; then
  source "prepare_armv6.sh"
fi

# Remove signing information
security delete-keychain "${KEY_CHAIN}"
